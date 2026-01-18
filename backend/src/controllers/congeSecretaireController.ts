import { Request, Response } from 'express';
import { query } from '../config/db';

// même logique que dans secretaireController
function getUserIdFromReq(req: Request): number | null {
  const q = req.query.userId;
  if (q && !Array.isArray(q) && !isNaN(Number(q))) return Number(q);

  const b = (req.body as any)?.userId;
  if (b !== undefined && !isNaN(Number(b))) return Number(b);

  return null;
}

// STRICT : seul un VRAI secrétaire peut gérer son congé (pas un enseignant remplaçant)
async function getSecretaireIdStrict(userId: number): Promise<number | null> {
  const r = await query(
    'SELECT secretaire_id FROM "Secretaire" WHERE utilisateur_id = $1 LIMIT 1',
    [userId]
  );
  return r.rows[0]?.secretaire_id ?? null;
}

// GET /api/dashboard/secretaire/conges/statut?userId=...
// Récupère le statut de congé et le(s) remplaçant(s) automatique(s)
export async function getStatutConge(req: Request, res: Response) {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) return res.status(400).json({ ok: false, error: 'userId manquant' });

    const secretaireId = await getSecretaireIdStrict(userId);
    if (!secretaireId) return res.status(403).json({ ok: false, error: 'Accès réservé secrétaire' });

    // Récupérer le statut en_conge
    const statutRes = await query(
      'SELECT en_conge FROM "Secretaire" WHERE secretaire_id = $1',
      [secretaireId]
    );
    const enConge = statutRes.rows[0]?.en_conge ?? false;

    // Récupérer les remplaçants automatiques (profs des groupes)
    const remplacantsRes = await query(
      `SELECT remplacant_user_id, remplacant_nom, remplacant_email, nom_groupe
       FROM v_remplacant_secretaire
       WHERE secretaire_id = $1`,
      [secretaireId]
    );

    return res.json({
      ok: true,
      enConge,
      remplacants: remplacantsRes.rows
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ ok: false, error: 'Erreur statut congé' });
  }
}

// POST /api/dashboard/secretaire/conges/toggle?userId=...
// Active ou désactive le mode congé (booléen simple)
export async function toggleConge(req: Request, res: Response) {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) return res.status(400).json({ ok: false, error: 'userId manquant' });

    const secretaireId = await getSecretaireIdStrict(userId);
    if (!secretaireId) return res.status(403).json({ ok: false, error: 'Accès réservé secrétaire' });

    const { enConge } = req.body || {};
    if (typeof enConge !== 'boolean') {
      return res.status(400).json({ ok: false, error: 'enConge (boolean) requis' });
    }

    await query(
      `INSERT INTO v_action_toggle_conge_secretaire (secretaire_id, en_conge)
       VALUES ($1, $2)`,
      [secretaireId, enConge]
    );

    // Récupérer les remplaçants pour informer l'utilisateur
    const remplacantsRes = await query(
      `SELECT remplacant_nom, remplacant_email, nom_groupe
       FROM v_remplacant_secretaire
       WHERE secretaire_id = $1`,
      [secretaireId]
    );

    return res.json({
      ok: true,
      enConge,
      message: enConge
        ? 'Mode congé activé. Les enseignants référents de vos groupes peuvent agir à votre place.'
        : 'Mode congé désactivé.',
      remplacants: remplacantsRes.rows
    });
  } catch (e: any) {
    console.error(e);
    return res.status(400).json({ ok: false, error: e?.message || 'Erreur toggle congé' });
  }
}

// ============ DEPRECATED - Gardé pour compatibilité temporaire ============

// GET /api/dashboard/secretaire/conges/remplacants?userId=...
// Retourne les remplaçants automatiques (pas de sélection manuelle)
export async function listRemplacants(req: Request, res: Response) {
  try {
    const userId = getUserIdFromReq(req);
    if (!userId) return res.status(400).json({ ok: false, error: 'userId manquant' });

    const secretaireId = await getSecretaireIdStrict(userId);
    if (!secretaireId) return res.status(403).json({ ok: false, error: 'Accès réservé secrétaire' });

    // Retourne les profs référents des groupes de cette secrétaire
    const r = await query(
      `SELECT DISTINCT remplacant_user_id AS utilisateur_id, 
              remplacant_nom AS nom, 
              remplacant_email AS email,
              nom_groupe
       FROM v_remplacant_secretaire
       WHERE secretaire_id = $1
       ORDER BY remplacant_nom`,
      [secretaireId]
    );

    return res.json({ ok: true, remplacants: r.rows });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ ok: false, error: 'Erreur liste remplacants' });
  }
}

// GET /api/dashboard/secretaire/conges?userId=...
// DEPRECATED : Retourne juste le statut en_conge (plus de liste de congés)
export async function getMesConges(req: Request, res: Response) {
  return getStatutConge(req, res);
}

// POST /api/dashboard/secretaire/conges?userId=...
// DEPRECATED : Redirige vers toggle
export async function declarerConge(req: Request, res: Response) {
  // Pour compatibilité : si on reçoit une requête, on active le congé
  req.body.enConge = true;
  return toggleConge(req, res);
}
