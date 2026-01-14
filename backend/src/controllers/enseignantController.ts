import { Request, Response } from 'express';
import { query } from '../config/db';
import { RegleLegale } from '../types/RegleLegale';
import { DashboardEnseignantStats } from '../types/Dashboard';
import {StatutValidationOffre} from "../enums/StatutValidationOffre";

// ==================== RÉFÉRENTIEL LÉGAL (CRUD) ====================

// GET /api/enseignant/referentiel - Lire toutes les règles légales
export const getReferentielLegal = async (_req: Request, res: Response) => {
    try {
        const result = await query<RegleLegale>('SELECT * FROM v_referentiel_legal ORDER BY pays, type_contrat');

        return res.status(200).json({
            ok: true,
            regles: result.rows
        });
    } catch (error: any) {
        console.error('Erreur lors de la récupération du référentiel:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la récupération du référentiel légal'
        });
    }
};

// POST /api/enseignant/referentiel - Créer une nouvelle règle
export const createRegleLegale = async (req: Request, res: Response) => {
    const { pays, type_contrat, remuneration_min, unite, duree_min_mois, duree_max_mois, date_effet } = req.body;

    // Validation
    if (!pays || !type_contrat || remuneration_min === undefined || !unite) {
        return res.status(400).json({
            ok: false,
            error: 'Pays, type_contrat, remuneration_min et unite sont requis'
        });
    }

    try {
        // Si date_effet n'est pas fourni, utiliser la date du jour
        const dateEffetFinal = date_effet || new Date().toISOString().split('T')[0];

        await query(
            `INSERT INTO v_referentiel_legal (pays, type_contrat, remuneration_min, unite, duree_min_mois, duree_max_mois, date_effet)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [pays, type_contrat, remuneration_min, unite, duree_min_mois || null, duree_max_mois || null, dateEffetFinal]
        );

        return res.status(201).json({
            ok: true,
            message: 'Règle légale créée avec succès'
        });
    } catch (error: any) {
        console.error('Erreur lors de la création de la règle:', error);

        // Gestion des erreurs de contrainte (duplicata, etc.)
        if (error.code === '23505') {
            return res.status(409).json({
                ok: false,
                error: 'Une règle existe déjà pour ce pays et type de contrat'
            });
        }

        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la création de la règle légale'
        });
    }
};

// PUT /api/enseignant/referentiel/:id - Modifier une règle existante
export const updateRegleLegale = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { pays, type_contrat, remuneration_min, unite, duree_min_mois, duree_max_mois, date_effet } = req.body;

    if (!id) {
        return res.status(400).json({
            ok: false,
            error: 'ID de règle requis'
        });
    }

    // Validation
    if (!pays || !type_contrat || remuneration_min === undefined || !unite) {
        return res.status(400).json({
            ok: false,
            error: 'Pays, type_contrat, remuneration_min et unite sont requis'
        });
    }

    try {
        // Si date_effet n'est pas fourni, utiliser la date du jour
        const dateEffetFinal = date_effet || new Date().toISOString().split('T')[0];

        const result = await query(
            `UPDATE v_referentiel_legal 
             SET pays = $1, type_contrat = $2, remuneration_min = $3, unite = $4, duree_min_mois = $5, duree_max_mois = $6, date_effet = $7
             WHERE regle_id = $8`,
            [pays, type_contrat, remuneration_min, unite, duree_min_mois || null, duree_max_mois || null, dateEffetFinal, id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({
                ok: false,
                error: 'Règle légale non trouvée'
            });
        }

        return res.status(200).json({
            ok: true,
            message: 'Règle légale mise à jour avec succès'
        });
    } catch (error: any) {
        console.error('Erreur lors de la mise à jour de la règle:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la mise à jour de la règle légale'
        });
    }
};

// DELETE /api/enseignant/referentiel/:id - Supprimer une règle
export const deleteRegleLegale = async (req: Request, res: Response) => {
    const { id } = req.params;

    if (!id) {
        return res.status(400).json({
            ok: false,
            error: 'ID de règle requis'
        });
    }

    try {
        const result = await query(
            'DELETE FROM v_referentiel_legal WHERE regle_id = $1',
            [id]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({
                ok: false,
                error: 'Règle légale non trouvée'
            });
        }

        return res.status(200).json({
            ok: true,
            message: 'Règle légale supprimée avec succès'
        });
    } catch (error: any) {
        console.error('Erreur lors de la suppression de la règle:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la suppression de la règle légale'
        });
    }
};

// ==================== DASHBOARD ENSEIGNANT ====================

// GET /api/enseignant/stats - Récupérer les statistiques du dashboard
export const getDashboardStats = async (_req: Request, res: Response) => {
    try {
        const result = await query<DashboardEnseignantStats>('SELECT * FROM v_dashboard_enseignant_stats');

        // Les stats sont normalement sur une seule ligne
        const stats = result.rows[0] || {
            offres_a_valider: 0,
            affectations_en_attente: 0,
            alertes_conformite: 0
        };

        return res.status(200).json({
            ok: true,
            stats
        });
    } catch (error: any) {
        console.error('Erreur lors de la récupération des stats:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la récupération des statistiques'
        });
    }
};

// GET /api/enseignant/offres-conformite - Récupérer les offres avec statut de conformité
export const getOffresConformite = async (_req: Request, res: Response) => {
    try {
        const result = await query(
            `SELECT * FROM v_offres_conformite 
             ORDER BY 
                CASE 
                    WHEN est_conforme = false THEN 0 
                    WHEN statut_validation = 'EN_ATTENTE' THEN 1 
                    ELSE 2 
                END,
                date_soumission DESC`
        );

        return res.status(200).json({
            ok: true,
            offres: result.rows
        });
    } catch (error: any) {
        console.error('Erreur lors de la récupération des offres:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la récupération des offres'
        });
    }
};

// POST /api/enseignant/offres/:id/review - Valider ou refuser une offre
export const reviewOffre = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { action, motif_refus } = req.body;

    if (!id) {
        return res.status(400).json({
            ok: false,
            error: 'ID d\'offre requis'
        });
    }

    if (!action || !['VALIDER', 'REFUSER'].includes(action)) {
        return res.status(400).json({
            ok: false,
            error: 'Action invalide. Utilisez VALIDER ou REFUSER'
        });
    }

    try {
        // Utilisation de la vue d'action pour la review
        const statut = action === 'VALIDER' ? StatutValidationOffre.VALIDE : StatutValidationOffre.REFUSE;

        await query(
            `UPDATE v_action_enseignant_review_offre 
             SET statut_validation = $1
             WHERE offre_id = $2`,
            [statut, id] // enseignant_id hardcodé à 1 pour le prototype
        );

        return res.status(200).json({
            ok: true,
            message: `Offre ${action === 'VALIDER' ? 'validée' : 'refusée'} avec succès`
        });
    } catch (error: any) {
        console.error('Erreur lors de la review de l\'offre:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la validation/refus de l\'offre'
        });
    }
};

// ==================== ARCHIVES ====================

// GET /api/enseignant/archives - Récupérer l'historique des stages validés
export const getArchivesStages = async (req: Request, res: Response) => {
    const { promo } = req.query;

    try {
        let result;

        if (promo) {
            // Filtrage par promotion
            result = await query(
                'SELECT * FROM v_archives_stages WHERE etudiant_promo = $1 ORDER BY date_debut_stage DESC',
                [promo]
            );
        } else {
            // Sans filtre : renvoie tout
            result = await query('SELECT * FROM v_archives_stages ORDER BY date_debut_stage DESC');
        }

        return res.status(200).json({
            ok: true,
            archives: result.rows
        });
    } catch (error: any) {
        console.error('Erreur lors de la récupération des archives:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la récupération des archives'
        });
    }
};
