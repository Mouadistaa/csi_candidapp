import { Request, Response } from 'express';
import { query } from '../config/db';
import { CandidatureAValider, PayloadValidation } from '../types/Affectation';

/**
 * Récupérer la liste des candidatures en attente de validation
 * @route GET /api/affectations/pending
 */
export async function getPending(_req: Request, res: Response) {
    try {
        const result = await query<CandidatureAValider>(
            `SELECT 
                candidature_id,
                nom_etudiant,
                prenom_etudiant,
                titre_offre,
                nom_entreprise,
                date_debut_offre,
                nom_groupe
            FROM v_candidatures_a_valider 
            ORDER BY date_debut_offre ASC`
        );

        return res.status(200).json({
            ok: true,
            candidatures: result.rows
        });
    } catch (error: any) {
        console.error('Erreur lors de la récupération des candidatures à valider:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la récupération des candidatures à valider'
        });
    }
}

/**
 * Valider une candidature et créer l'affectation de stage
 * @route POST /api/affectations
 */
export async function validate(req: Request, res: Response) {
    const { candidature_id }: PayloadValidation = req.body;

    // Validation du payload
    if (!candidature_id || typeof candidature_id !== 'number') {
        return res.status(400).json({
            ok: false,
            error: 'candidature_id est requis et doit être un nombre'
        });
    }

    try {
        // Fire & Forget - Pas de RETURNING (le trigger gère la logique)
        await query(
            'INSERT INTO v_action_creer_affectation (candidature_id) VALUES ($1)',
            [candidature_id]
        );

        // Si on arrive ici sans exception, le trigger a validé l'opération
        return res.status(201).json({
            ok: true,
            message: 'Stage validé avec succès'
        });

    } catch (error: any) {
        console.error('Erreur lors de la validation du stage:', error);

        // Gestion des erreurs spécifiques du trigger
        const errorMessage = error.message || '';

        // Candidature introuvable
        if (
            errorMessage.includes('introuvable') ||
            errorMessage.includes('not found') ||
            errorMessage.includes('n\'existe pas')
        ) {
            return res.status(404).json({
                ok: false,
                error: 'Candidature introuvable'
            });
        }

        // Candidature déjà validée ou statut incorrect
        if (
            errorMessage.includes('déjà') ||
            errorMessage.includes('already') ||
            errorMessage.includes('RETENU') ||
            errorMessage.includes('statut') ||
            error.code === '23505' // Duplicate key violation
        ) {
            return res.status(400).json({
                ok: false,
                error: 'Cette candidature a déjà été validée ou n\'est pas au statut RETENU'
            });
        }

        // Erreur générique règle métier
        if (error.code === 'P0001' || errorMessage.includes('RAISE')) {
            return res.status(400).json({
                ok: false,
                error: errorMessage.replace(/^ERROR:\s*/, '') || 'Règle métier non respectée'
            });
        }

        // Erreur serveur générique
        return res.status(500).json({
            ok: false,
            error: 'Erreur interne lors de la validation du stage'
        });
    }
}

/**
 * Refuser une candidature (Refus Pédagogique)
 * @route POST /api/affectations/refuse
 */
export async function refuseCandidature(req: Request, res: Response) {
    const { candidature_id }: PayloadValidation = req.body;

    // Validation du payload
    if (!candidature_id || typeof candidature_id !== 'number') {
        return res.status(400).json({
            ok: false,
            error: 'candidature_id est requis et doit être un nombre'
        });
    }

    try {
        // Fire & Forget - Pas de RETURNING (le trigger gère la logique)
        await query(
            'INSERT INTO v_action_refuser_candidature (candidature_id) VALUES ($1)',
            [candidature_id]
        );

        // Si on arrive ici sans exception, le trigger a validé l'opération
        return res.status(200).json({
            ok: true,
            message: 'Candidature refusée'
        });

    } catch (error: any) {
        console.error('Erreur lors du refus de la candidature:', error);

        // Gestion des erreurs spécifiques du trigger
        const errorMessage = error.message || '';

        // Action impossible/illégale (messages du trigger)
        if (
            errorMessage.includes('Action impossible') ||
            errorMessage.includes('Action illégale') ||
            errorMessage.includes('déjà') ||
            errorMessage.includes('already') ||
            errorMessage.includes('statut')
        ) {
            return res.status(409).json({
                ok: false,
                error: errorMessage.replace(/^ERROR:\s*/, '') || 'Cette action n\'est pas autorisée pour cette candidature'
            });
        }

        // Candidature introuvable
        if (
            errorMessage.includes('introuvable') ||
            errorMessage.includes('not found') ||
            errorMessage.includes('n\'existe pas')
        ) {
            return res.status(404).json({
                ok: false,
                error: 'Candidature introuvable'
            });
        }

        // Erreur générique règle métier
        if (error.code === 'P0001' || errorMessage.includes('RAISE')) {
            return res.status(400).json({
                ok: false,
                error: errorMessage.replace(/^ERROR:\s*/, '') || 'Règle métier non respectée'
            });
        }

        // Erreur serveur générique
        return res.status(500).json({
            ok: false,
            error: 'Erreur interne lors du refus de la candidature'
        });
    }
}
