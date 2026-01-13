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

    const sql = `
      SELECT active, pending, candidatures
      FROM v_dashboard_entreprise_stats
      WHERE entreprise_id = $1
      LIMIT 1
    `;
    const result = await query(sql, [entrepriseId]);

    // ✅ Garde-fou : si aucune ligne, on renvoie 0/0/0 au lieu de crash
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

    return res.status(200).json({ ok: true, candidatures: result.rows });
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
