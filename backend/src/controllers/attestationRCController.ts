import {Request, Response} from 'express';
import {query} from '../config/db';
import {AttestationRC} from '../types/AttestationRC';

async function getEtudiantIdFromUserId(userId: number): Promise<number | null> {
    const r = await query(
        'SELECT etudiant_id FROM v_profil_etudiant WHERE utilisateur_id = $1 LIMIT 1',
        [userId]
    );
    return r.rows[0]?.etudiant_id ?? null;
}

/**
 * POST /api/attestation-rc/me
 * Récupérer l'attestation RC de l'étudiant connecté
 */
export async function getMyAttestationRCHandler(req: Request, res: Response) {
    const {userId, role} = req.body;

    if (!userId) return res.status(400).json({ok: false, error: 'userId requis'});
    if (role !== 'ETUDIANT') {
        return res.status(403).json({ok: false, error: 'Accès interdit - réservé aux étudiants'});
    }

    try {
        const etudiantId = await getEtudiantIdFromUserId(Number(userId));
        if (!etudiantId) {
            return res.status(404).json({ok: false, error: 'Profil étudiant introuvable'});
        }

        const result = await query<AttestationRC>(
            `SELECT etudiant_id, statut, fichier_url, date_depot, date_validation
             FROM v_attestation_rc_etudiant 
             WHERE utilisateur_id = $1`,
                [userId]
        );

        return res.status(200).json({
            ok: true,
            attestation: result.rows[0] || null
        });
    } catch (err) {
        console.error('Erreur getMyAttestationRCHandler:', err);
        return res.status(500).json({ok: false, error: 'Erreur serveur'});
    }
}

/**
 * POST /api/attestation-rc/deposer
 * Déposer ou redéposer l'attestation RC (Data URL PDF)
 */
export async function deposerAttestationRCHandler(req: Request, res: Response) {
    const {userId, role, fichierDataUrl} = req.body;

    if (!userId) return res.status(400).json({ok: false, error: 'userId requis'});
    if (role !== 'ETUDIANT') {
        return res.status(403).json({ok: false, error: 'Accès interdit - réservé aux étudiants'});
    }

    if (!fichierDataUrl || typeof fichierDataUrl !== 'string') {
        return res.status(400).json({ok: false, error: 'fichierDataUrl requis'});
    }

    // Petit garde-fou (ajuste si besoin)
    if (fichierDataUrl.length > 3_000_000) {
        return res.status(413).json({ok: false, error: 'Fichier trop volumineux (limite ~3MB)'});
    }

    if (!fichierDataUrl.startsWith('data:application/pdf')) {
        return res.status(400).json({ok: false, error: 'Format invalide : PDF requis'});
    }

    try {
        const etudiantId = await getEtudiantIdFromUserId(Number(userId));
        if (!etudiantId) {
            return res.status(404).json({ok: false, error: 'Profil étudiant introuvable'});
        }

        // Passe par la vue d'action => trigger fait la logique (1er dépôt / redépôt si REFUSE)
        await query(
            'INSERT INTO v_action_deposer_attestation_rc (etudiant_id, fichier_url) VALUES ($1, $2)',
            [etudiantId, fichierDataUrl]
        );

        return res.status(200).json({
            ok: true,
            message: 'Attestation RC déposée. Statut : EN_ATTENTE'
        });

    } catch (error: any) {
        console.error('Erreur deposerAttestationRCHandler:', error);

        if (error.message?.includes('Dépôt impossible')) {
            return res.status(400).json({ok: false, error: error.message});
        }

        return res.status(500).json({ok: false, error: 'Erreur lors du dépôt de l’attestation RC'});
    }
}