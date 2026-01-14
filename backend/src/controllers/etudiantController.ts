import { Request, Response } from 'express';
import { query } from '../config/db';

// GET /api/etudiant/profile - Récupérer le profil étudiant
export async function getProfile(req: Request, res: Response) {
    const { userId, role } = req.body;

    if (!userId || role !== 'ETUDIANT') {
        return res.status(403).json({ error: 'FORBIDDEN' });
    }

    try {
        const result = await query<{
            etudiant_id: number;
            nom: string;
            prenom: string;
            formation: string;
            promo: string | null;
            cv_url: string | null;
            en_recherche: boolean;
            profil_visible: boolean;
        }>(
            `SELECT etudiant_id, nom, prenom, formation, promo, cv_url, en_recherche, profil_visible
             FROM "v_profil_etudiant"
             WHERE utilisateur_id = $1`,
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'ETUDIANT_NOT_FOUND' });
        }

        return res.json({ ok: true, profile: result.rows[0] });
    } catch (err) {
        console.error('Erreur getProfile:', err);
        return res.status(500).json({ error: 'DB_ERROR' });
    }
}

// PATCH /api/etudiant/recherche - Mettre à jour le statut de recherche
export async function updateRecherche(req: Request, res: Response) {
    const { userId, role, enRecherche } = req.body;

    if (!userId || role !== 'ETUDIANT') {
        return res.status(403).json({ error: 'FORBIDDEN' });
    }

    if (typeof enRecherche !== 'boolean') {
        return res.status(400).json({ error: 'INVALID_PARAM' });
    }

    try {
        const result = await query(
            `UPDATE v_action_update_profil_etudiant SET en_recherche = $1 WHERE utilisateur_id = $2 RETURNING en_recherche`,
            [enRecherche, userId]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'ETUDIANT_NOT_FOUND' });
        }

        return res.json({ ok: true, enRecherche: result.rows[0].en_recherche });
    } catch (err) {
        console.error('Erreur updateRecherche:', err);
        return res.status(500).json({ error: 'DB_ERROR' });
    }
}

// POST /api/etudiant/cv - Déposer un CV (base64)
export async function uploadCV(req: Request, res: Response) {
    const { userId, role, cvBase64 } = req.body;

    if (!userId || role !== 'ETUDIANT') {
        return res.status(403).json({ error: 'FORBIDDEN' });
    }

    if (!cvBase64 || typeof cvBase64 !== 'string') {
        return res.status(400).json({ error: 'CV_REQUIRED' });
    }

    // Vérifier que c'est un PDF en base64 (data:application/pdf;base64,...)
    if (!cvBase64.startsWith('data:application/pdf;base64,')) {
        return res.status(400).json({ error: 'INVALID_FORMAT', message: 'Le CV doit être un fichier PDF' });
    }

    // Vérifier la taille (limite ~5MB en base64)
    const base64Data = cvBase64.split(',')[1];
    const sizeInBytes = (base64Data.length * 3) / 4;
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (sizeInBytes > maxSize) {
        return res.status(400).json({ error: 'FILE_TOO_LARGE', message: 'Le CV ne doit pas dépasser 5MB' });
    }

    try {
        const result = await query(
            `UPDATE v_action_update_profil_etudiant SET cv_url = $1 WHERE utilisateur_id = $2 RETURNING cv_url`,
            [cvBase64, userId]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'ETUDIANT_NOT_FOUND' });
        }

        return res.json({ ok: true, message: 'CV déposé avec succès' });
    } catch (err) {
        console.error('Erreur uploadCV:', err);
        return res.status(500).json({ error: 'DB_ERROR' });
    }
}

// DELETE /api/etudiant/cv - Supprimer le CV
export async function deleteCV(req: Request, res: Response) {
    const { userId, role } = req.body;

    if (!userId || role !== 'ETUDIANT') {
        return res.status(403).json({ error: 'FORBIDDEN' });
    }

    try {
        const result = await query(
            `UPDATE v_action_update_profil_etudiant SET cv_url = NULL WHERE utilisateur_id = $1 RETURNING cv_url`,
            [userId]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'ETUDIANT_NOT_FOUND' });
        }

        return res.json({ ok: true, message: 'CV supprimé' });
    } catch (err) {
        console.error('Erreur deleteCV:', err);
        return res.status(500).json({ error: 'DB_ERROR' });
    }
}
