import { Request, Response } from 'express';
import { query, getClient } from '../config/db';
import * as bcrypt from 'bcrypt';
import { DashboardSecretaireStats } from '../types/Dashboard';

/* =========================================================
   HELPERS (userId sans middleware + secretaireId via VUE)
   ========================================================= */

function getUserIdFromReq(req: Request): number | null {
  const q = req.query.userId;
  if (q && !Array.isArray(q) && !isNaN(Number(q))) return Number(q);

  const b = (req.body as any)?.userId;
  if (b !== undefined && !isNaN(Number(b))) return Number(b);

  return null;
}

// ✅ IMPORTANT : passer par une vue (pas de SELECT direct sur "Secretaire")
async function getSecretaireIdFromUserId(userId: number): Promise<number | null> {
  const r = await query(
    'SELECT secretaire_id FROM v_secretaire_by_user WHERE utilisateur_id = $1 LIMIT 1',
    [userId]
  );
  return r.rows[0]?.secretaire_id ?? null;
}

/* =========================================================
   DASHBOARD SECRÉTAIRE
   ========================================================= */

// GET /api/dashboard/secretaire/stats
export const getDashboardStats = async (_req: Request, res: Response) => {
  try {
    const result = await query<DashboardSecretaireStats>('SELECT * FROM v_dashboard_secretaire_stats');

    const stats = result.rows[0] || {
      nb_etudiants_total: 0,
      nb_etudiants_en_recherche: 0,
      nb_attestations_a_valider: 0,
      nb_stages_actes: 0,
      nb_entreprises_partenaires: 0
    };

    return res.status(200).json({ ok: true, stats });
  } catch (error: any) {
    console.error('Erreur lors de la récupération des stats secrétaire:', error);
    return res.status(500).json({ ok: false, error: 'Erreur lors de la récupération des statistiques' });
  }
};

/* =========================================================
   ATTESTATIONS RC (100% VUES)
   ========================================================= */

/**
 * GET /api/dashboard/secretaire/attestations?userId=...
 * ✅ SELECT via v_attestations_rc_a_valider
 */
export const getAttestationsAValider = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) return res.status(400).json({ ok: false, error: 'userId manquant' });

    const secretaireId = await getSecretaireIdFromUserId(userId);
    if (!secretaireId) {
      return res.status(403).json({ ok: false, error: 'Accès interdit (profil secrétaire introuvable)' });
    }

    const result = await query('SELECT * FROM v_attestations_rc_a_valider');
    return res.status(200).json({ ok: true, attestations: result.rows });

  } catch (error: any) {
    console.error('Erreur chargement attestations:', error);
    return res.status(500).json({ ok: false, error: 'Erreur chargement attestations' });
  }
};

/**
 * POST /api/dashboard/secretaire/attestations/:etudiantId/valider?userId=...
 * ✅ UPDATE via v_action_valider_attestation_rc + trigger
 */
export const validerAttestationRC = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) return res.status(400).json({ ok: false, error: 'userId manquant' });

    const secretaireId = await getSecretaireIdFromUserId(userId);
    if (!secretaireId) {
      return res.status(403).json({ ok: false, error: 'Accès interdit (profil secrétaire introuvable)' });
    }

    const etudiantId = Number(req.params.etudiantId);
    if (!etudiantId || Number.isNaN(etudiantId)) {
      return res.status(400).json({ ok: false, error: 'etudiantId invalide' });
    }

    await query(
      `UPDATE v_action_valider_attestation_rc
       SET decision = $1, motif_refus = $2, secretaire_id = $3
       WHERE etudiant_id = $4`,
      ['VALIDER', null, secretaireId, etudiantId]
    );

    return res.status(200).json({ ok: true, message: 'Attestation RC validée' });

  } catch (error: any) {
    console.error('Erreur validation RC:', error);
    return res.status(400).json({ ok: false, error: error.message || 'Erreur validation RC' });
  }
};

/**
 * POST /api/dashboard/secretaire/attestations/:etudiantId/refuser?userId=...
 * body: { motif_refus?: string }
 * ✅ UPDATE via v_action_valider_attestation_rc + trigger
 */
export const refuserAttestationRC = async (req: Request, res: Response) => {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) return res.status(400).json({ ok: false, error: 'userId manquant' });

    const secretaireId = await getSecretaireIdFromUserId(userId);
    if (!secretaireId) {
      return res.status(403).json({ ok: false, error: 'Accès interdit (profil secrétaire introuvable)' });
    }

    const etudiantId = Number(req.params.etudiantId);
    if (!etudiantId || Number.isNaN(etudiantId)) {
      return res.status(400).json({ ok: false, error: 'etudiantId invalide' });
    }

    const { motif_refus } = req.body || {};

    await query(
      `UPDATE v_action_valider_attestation_rc
       SET decision = $1, motif_refus = $2, secretaire_id = $3
       WHERE etudiant_id = $4`,
      ['REFUSER', motif_refus || null, secretaireId, etudiantId]
    );

    return res.status(200).json({ ok: true, message: 'Attestation RC refusée' });

  } catch (error: any) {
    console.error('Erreur refus RC:', error);
    return res.status(400).json({ ok: false, error: error.message || 'Erreur refus RC' });
  }
};

/* =========================================================
   CRÉATION ÉTUDIANT (ton code inchangé)
   ========================================================= */

// POST /api/dashboard/secretaire/etudiants
export const creerEtudiant = async (req: Request, res: Response) => {
  const { nom, prenom, email, password, formation, promo } = req.body;

  if (!nom || !prenom || !email || !password || !formation) {
    return res.status(400).json({ error: "Tous les champs sont obligatoires" });
  }

  const client = await getClient();

  try {
    await client.query('BEGIN');

    const checkEmail = await client.query('SELECT id FROM "Utilisateur" WHERE email = $1', [email]);
    if (checkEmail.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: "Cet email est déjà utilisé" });
    }

    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    const userQuery = `
      INSERT INTO "Utilisateur" (email, password_hash, role, actif, nom)
      VALUES ($1, $2, 'ETUDIANT', true, $3)
      RETURNING id
    `;
    const userRes = await client.query(userQuery, [email, passwordHash, nom]);
    const newUserId = userRes.rows[0].id;

    const etudiantQuery = `
      INSERT INTO "Etudiant" (utilisateur_id, nom, prenom, formation, promo, en_recherche)
      VALUES ($1, $2, $3, $4, $5, true)
      RETURNING etudiant_id
    `;
    await client.query(etudiantQuery, [newUserId, nom, prenom, formation, promo]);

    await client.query('COMMIT');

    return res.status(201).json({
      ok: true,
      message: "Compte étudiant créé avec succès",
      id: newUserId
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error("Erreur création étudiant:", error);
    return res.status(500).json({ error: "Erreur lors de la création de l'étudiant" });
  } finally {
    client.release();
  }
};
