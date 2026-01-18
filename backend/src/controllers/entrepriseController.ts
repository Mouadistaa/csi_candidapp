import { Request, Response } from 'express';
import { query } from '../config/db';

/**
 * Règle projet :
 * ✅ SELECT via vues
 * ✅ INSERT/UPDATE/DELETE via vues d’action + triggers
 */

/* ===================== HELPERS ===================== */

// userId peut venir de ?userId=... (query) ou du body
function getUserIdFromReq(req: Request): number | null {
  const q = req.query.userId;
  if (q && !Array.isArray(q) && !isNaN(Number(q))) return Number(q);

  const b = (req.body as any)?.userId;
  if (b !== undefined && !isNaN(Number(b))) return Number(b);

  return null;
}

// Helper : trouver entreprise_id via userId (via vue)
async function getEntrepriseIdFromUser(userId: number): Promise<number | null> {
  const res = await query(
    `SELECT entreprise_id
     FROM v_user_entreprise
     WHERE utilisateur_id = $1
     LIMIT 1`,
    [userId]
  );
  return res.rows[0]?.entreprise_id ?? null;
}

// Convert safe number (évite NaN si null/undefined/texte)
function toSafeNumber(value: any, fallback = 0): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

/* ===================== 1) STATS ===================== */
// GET /api/entreprise/stats?userId=...
export const getStats = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) {
      return res.status(400).json({
        ok: false,
        error: 'userId manquant (query ?userId=... ou body.userId)',
      });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    // Requête directe pour des stats fiables
    const sql = `
      SELECT 
        COALESCE(COUNT(*) FILTER (WHERE statut_validation = 'VALIDE'), 0) AS active,
        COALESCE(COUNT(*) FILTER (WHERE statut_validation = 'EN_ATTENTE'), 0) AS pending,
        COALESCE((
          SELECT COUNT(*) 
          FROM "Candidature" c 
          JOIN "Offre" o2 ON o2.id = c.offre_id 
          WHERE o2.entreprise_id = $1
            AND c.statut NOT IN ('ANNULE', 'REFUSE')
        ), 0) AS candidatures
      FROM "Offre"
      WHERE entreprise_id = $1
    `;
    const result = await query(sql, [entrepriseId]);

    const row = result.rows[0] ?? { active: 0, pending: 0, candidatures: 0 };

    const stats = {
      active: toSafeNumber(row.active, 0),
      pending: toSafeNumber(row.pending, 0),
      candidatures: toSafeNumber(row.candidatures, 0),
    };

    return res.status(200).json({ ok: true, stats });
  } catch (error) {
    console.error('getStats error:', error);
    return res.status(500).json({ ok: false, error: 'Erreur stats' });
  }
};

/* ===================== 2) MES OFFRES ===================== */
// GET /api/entreprise/mes-offres?userId=...
export const getMesOffres = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) {
      return res.status(400).json({
        ok: false,
        error: 'userId manquant (query ?userId=... ou body.userId)',
      });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    const sql = `
      SELECT *
      FROM v_mes_offres_entreprise
      WHERE entreprise_id = $1
      ORDER BY date_soumission DESC
    `;
    const result = await query(sql, [entrepriseId]);

    return res.status(200).json({ ok: true, offres: result.rows });
  } catch (error) {
    console.error('getMesOffres error:', error);
    return res.status(500).json({ ok: false, error: 'Erreur offres' });
  }
};

/* ===================== 3) CANDIDATURES RECUES ===================== */
// GET /api/entreprise/candidatures?userId=...
export const getCandidaturesRecues = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) {
      return res.status(400).json({
        ok: false,
        error: 'userId manquant (query ?userId=... ou body.userId)',
      });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    const sql = `
      SELECT *
      FROM v_candidatures_recues_entreprise
      WHERE entreprise_id = $1
      ORDER BY date_candidature DESC
    `;
    const result = await query(sql, [entrepriseId]);

    const offreId = req.query.offreId && !Array.isArray(req.query.offreId)
    ? Number(req.query.offreId)
    : null;

    let rows = result.rows;

    if (offreId && Number.isFinite(offreId)) {
    rows = rows.filter((r: any) => {
        const oid = Number(r.offre_id ?? r.id_offre ?? r.offreid ?? r.offreId);
        return Number.isFinite(oid) ? oid === offreId : false;
    });
    }

    return res.status(200).json({ ok: true, candidatures: rows });
  } catch (error) {
    console.error('getCandidaturesRecues error:', error);
    return res.status(500).json({ ok: false, error: 'Erreur candidatures' });
  }
};

/* ===================== 4) DECIDER CANDIDATURE ===================== */
// POST /api/entreprise/candidatures/decision?userId=...
// body: { candidatureId, decision }
export const deciderCandidature = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) {
      return res.status(400).json({
        ok: false,
        error: 'userId manquant (query ?userId=... ou body.userId)',
      });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    const { candidatureId, decision } = req.body || {};
    if (!candidatureId || !decision) {
      return res.status(400).json({ ok: false, error: 'candidatureId et decision requis' });
    }

    // ✅ via vue d’action (sécurisée : l’offre doit appartenir à l’entreprise)
    const sql = `
      UPDATE v_action_entreprise_decider_candidature
      SET statut = $1
      WHERE candidature_id = $2
        AND entreprise_id = $3
      RETURNING candidature_id
    `;
    const result = await query(sql, [decision, candidatureId, entrepriseId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ ok: false, error: 'Introuvable ou non autorisé' });
    }

    return res.status(200).json({ ok: true, message: `Candidature ${decision}` });
  } catch (error) {
    console.error('deciderCandidature error:', error);
    return res.status(500).json({ ok: false, error: 'Erreur décision' });
  }
};

/* ===================== 5) CREER OFFRE ===================== */
// POST /api/entreprise/offres?userId=...
// body: { type, titre, description, competences, localisation_pays, localisation_ville, duree_mois, remuneration, date_debut, date_expiration }
export const createOffre = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) {
      return res.status(400).json({ ok: false, error: 'userId manquant (query ?userId=... ou body.userId)' });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    const {
      type,
      titre,
      description,
      competences,
      localisation_pays,
      localisation_ville,
      duree_mois,
      remuneration,
      date_debut,
      date_expiration,
    } = req.body || {};

    // Validation minimale (les NOT NULL de la table/vues)
    if (
      !type ||
      !titre ||
      !localisation_pays ||
      duree_mois === undefined ||
      remuneration === undefined ||
      !date_debut ||
      !date_expiration
    ) {
      return res.status(400).json({
        ok: false,
        error:
          'Champs requis: type, titre, localisation_pays, duree_mois, remuneration, date_debut, date_expiration',
      });
    }

    const sql = `
      INSERT INTO v_action_creer_offre (
        entreprise_id, type, titre, description, competences,
        localisation_pays, localisation_ville,
        duree_mois, remuneration, date_debut, date_expiration
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      RETURNING id
    `;

    const params = [
      entrepriseId,
      type,
      titre,
      description ?? null,
      competences ?? null,
      localisation_pays,
      localisation_ville ?? null,
      Number(duree_mois),
      Number(remuneration),
      date_debut,
      date_expiration,
    ];

    const result = await query(sql, params);
    const newId = result.rows?.[0]?.id ?? null;

    return res.status(201).json({
      ok: true,
      message: 'Offre créée (soumise) avec succès',
      id: newId,
    });
  } catch (error) {
    console.error('createOffre error:', error);
    return res.status(500).json({ ok: false, error: 'Erreur création offre' });
  }
};

/* ===================== 6) MODIFIER OFFRE ===================== */
// PUT /api/entreprise/offres/:id?userId=...
// body: { type, titre, description, competences, localisation_pays, localisation_ville, duree_mois, remuneration, date_debut, date_expiration }
export const updateOffre = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    const offreId = Number(req.params.id);

    if (!userId) {
      return res.status(400).json({ ok: false, error: 'userId manquant' });
    }

    if (!offreId || isNaN(offreId)) {
      return res.status(400).json({ ok: false, error: 'ID offre invalide' });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    const {
      type,
      titre,
      description,
      competences,
      localisation_pays,
      localisation_ville,
      duree_mois,
      remuneration,
      date_debut,
      date_expiration,
    } = req.body || {};

    // Validation minimale
    if (
      !type ||
      !titre ||
      !localisation_pays ||
      duree_mois === undefined ||
      remuneration === undefined ||
      !date_debut ||
      !date_expiration
    ) {
      return res.status(400).json({
        ok: false,
        error: 'Champs requis: type, titre, localisation_pays, duree_mois, remuneration, date_debut, date_expiration',
      });
    }

    // Vérifier que l'offre appartient à l'entreprise et récupérer les anciennes valeurs
    const oldOffreResult = await query(
      `SELECT type, duree_mois, remuneration, date_debut, date_expiration, statut_validation
       FROM "Offre"
       WHERE id = $1 AND entreprise_id = $2`,
      [offreId, entrepriseId]
    );

    if (oldOffreResult.rows.length === 0) {
      return res.status(404).json({ ok: false, error: 'Offre introuvable ou non autorisée' });
    }

    const oldOffre = oldOffreResult.rows[0];

    // Vérifier s'il y a des affectations actives
    const affectationCheck = await query(
      `SELECT 1 FROM "Affectation" a
       JOIN "Candidature" c ON c.id = a.candidature_id
       WHERE c.offre_id = $1
       LIMIT 1`,
      [offreId]
    );

    if (affectationCheck.rows.length > 0) {
      return res.status(400).json({
        ok: false,
        error: 'Impossible de modifier cette offre : elle a des affectations en cours.'
      });
    }

    // Déterminer si une revalidation est nécessaire (critères sensibles modifiés)
    let needsRevalidation = false;
    if (oldOffre.statut_validation === 'VALIDE') {
      if (
        type !== oldOffre.type ||
        Number(duree_mois) !== oldOffre.duree_mois ||
        Number(remuneration) !== Number(oldOffre.remuneration) ||
        date_debut !== oldOffre.date_debut?.toISOString?.()?.split('T')[0] ||
        date_expiration !== oldOffre.date_expiration?.toISOString?.()?.split('T')[0]
      ) {
        needsRevalidation = true;
      }
    }

    // Mettre à jour l'offre
    const sql = `
      UPDATE "Offre"
      SET type = $1,
          titre = $2,
          description = $3,
          competences = $4,
          localisation_pays = $5,
          localisation_ville = $6,
          duree_mois = $7,
          remuneration = $8,
          date_debut = $9,
          date_expiration = $10,
          statut_validation = CASE WHEN $13 THEN 'EN_ATTENTE' ELSE statut_validation END,
          date_soumission = CASE WHEN $13 THEN CURRENT_DATE ELSE date_soumission END,
          date_validation = CASE WHEN $13 THEN NULL ELSE date_validation END
      WHERE id = $11
        AND entreprise_id = $12
      RETURNING id
    `;

    const params = [
      type,
      titre,
      description ?? null,
      competences ?? null,
      localisation_pays,
      localisation_ville ?? null,
      Number(duree_mois),
      Number(remuneration),
      date_debut,
      date_expiration,
      offreId,
      entrepriseId,
      needsRevalidation,
    ];

    const result = await query(sql, params);

    if (result.rowCount === 0) {
      return res.status(404).json({ ok: false, error: 'Offre introuvable ou non autorisée' });
    }


    return res.status(200).json({
      ok: true,
      message: needsRevalidation
        ? 'Offre modifiée. Les modifications nécessitent une nouvelle validation par l\'enseignant.'
        : 'Offre modifiée avec succès.',
      needsRevalidation,
    });
  } catch (error: any) {
    console.error('updateOffre error:', error);

    // Gestion des erreurs spécifiques du trigger
    if (error.message?.includes('candidatures actives') || error.message?.includes('affectation')) {
      return res.status(400).json({
        ok: false,
        error: 'Impossible de modifier cette offre : elle a des candidatures ou affectations en cours.'
      });
    }

    return res.status(500).json({ ok: false, error: 'Erreur modification offre' });
  }
};

/* ===================== 7) SUPPRIMER OFFRE ===================== */
// DELETE /api/entreprise/offres/:id?userId=...
export const deleteOffre = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    const offreId = Number(req.params.id);

    if (!userId) {
      return res.status(400).json({ ok: false, error: 'userId manquant' });
    }

    if (!offreId || isNaN(offreId)) {
      return res.status(400).json({ ok: false, error: 'ID offre invalide' });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    // Vérifier que l'offre appartient à l'entreprise
    const offreCheck = await query(
      `SELECT 1 FROM "Offre" WHERE id = $1 AND entreprise_id = $2`,
      [offreId, entrepriseId]
    );

    if (offreCheck.rows.length === 0) {
      return res.status(404).json({ ok: false, error: 'Offre introuvable ou non autorisée' });
    }

    // Vérifier s'il y a des candidatures actives
    const candidaturesCheck = await query(
      `SELECT 1 FROM "Candidature"
       WHERE offre_id = $1 AND statut NOT IN ('ANNULE', 'REFUSE')
       LIMIT 1`,
      [offreId]
    );

    if (candidaturesCheck.rows.length > 0) {
      return res.status(400).json({
        ok: false,
        error: 'Impossible de supprimer cette offre : elle a des candidatures actives.'
      });
    }

    // Vérifier s'il y a des affectations
    const affectationsCheck = await query(
      `SELECT 1 FROM "Affectation" a
       JOIN "Candidature" c ON c.id = a.candidature_id
       WHERE c.offre_id = $1
       LIMIT 1`,
      [offreId]
    );

    if (affectationsCheck.rows.length > 0) {
      return res.status(400).json({
        ok: false,
        error: 'Impossible de supprimer cette offre : elle a des affectations en cours.'
      });
    }

    // Supprimer les candidatures annulées/refusées associées
    await query(`DELETE FROM "Candidature" WHERE offre_id = $1`, [offreId]);

    // Supprimer l'offre
    const result = await query(
      `DELETE FROM "Offre" WHERE id = $1 AND entreprise_id = $2 RETURNING id`,
      [offreId, entrepriseId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ ok: false, error: 'Offre introuvable ou non autorisée' });
    }

    return res.status(200).json({
      ok: true,
      message: 'Offre supprimée avec succès',
    });
  } catch (error: any) {
    console.error('deleteOffre error:', error);


    return res.status(500).json({ ok: false, error: 'Erreur suppression offre' });
  }
};

/* ===================== 8) OBTENIR UNE OFFRE ===================== */
// GET /api/entreprise/offres/:id?userId=...
export const getOffreById = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    const offreId = Number(req.params.id);

    if (!userId) {
      return res.status(400).json({ ok: false, error: 'userId manquant' });
    }

    if (!offreId || isNaN(offreId)) {
      return res.status(400).json({ ok: false, error: 'ID offre invalide' });
    }

    const entrepriseId = await getEntrepriseIdFromUser(userId);
    if (!entrepriseId) {
      return res.status(403).json({ ok: false, error: 'Profil entreprise introuvable' });
    }

    const sql = `
      SELECT 
        o.id AS offre_id,
        o.entreprise_id,
        o.type,
        o.titre,
        o.description,
        o.competences,
        o.localisation_pays,
        o.localisation_ville,
        o.duree_mois,
        o.remuneration,
        o.date_debut,
        o.date_expiration,
        o.statut_validation,
        o.date_soumission,
        o.date_validation
      FROM "Offre" o
      WHERE o.id = $1
        AND o.entreprise_id = $2
      LIMIT 1
    `;

    const result = await query(sql, [offreId, entrepriseId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ ok: false, error: 'Offre introuvable' });
    }

    return res.status(200).json({ ok: true, offre: result.rows[0] });
  } catch (error) {
    console.error('getOffreById error:', error);
    return res.status(500).json({ ok: false, error: 'Erreur récupération offre' });
  }
};
