import { Request, Response } from 'express';
import { query } from '../config/db';

// ==================== DASHBOARD SECRÉTAIRE ====================

// GET /api/dashboard/secretaire/stats - Récupérer les statistiques du dashboard secrétaire
export const getDashboardStats = async (_req: Request, res: Response) => {
    try {
        const result = await query('SELECT * FROM v_dashboard_secretaire_stats');

        // Les stats sont normalement sur une seule ligne
        const stats = result.rows[0] || {
            nb_etudiants_total: 0,
            nb_etudiants_en_recherche: 0,
            nb_attestations_a_valider: 0,
            nb_stages_actes: 0,
            nb_entreprises_partenaires: 0
        };

        return res.status(200).json({
            ok: true,
            stats
        });
    } catch (error: any) {
        console.error('Erreur lors de la récupération des stats secrétaire:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la récupération des statistiques'
        });
    }
};
