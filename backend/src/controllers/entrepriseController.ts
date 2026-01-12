import { Request, Response } from 'express';
import { query } from '../config/db';

// 1. Voir SES offres (Entreprise)
export const getMesOffres = async (req: Request, res: Response) => {
    try {
        // En attendant que ton middleware d'auth soit fini, on simule l'ID
        // d'entreprise 2 (TechCorp Solutions dans ton script SQL)
        const entrepriseId = 2; 

        const result = await query(
            'SELECT * FROM "Offre" WHERE "entreprise_id" = $1 ORDER BY "date_soumission" DESC', 
            [entrepriseId]
        );
        res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Erreur récupération offres" });
    }
};

// 2. Voir les candidatures reçues
export const getCandidaturesRecues = async (req: Request, res: Response) => {
    try {
        const entrepriseId = 2; 
        
        const sql = `
            SELECT c.id as candidature_id, c.statut, o.titre as offre_titre, e.nom, e.prenom, e.cv_url
            FROM "Candidature" c
            JOIN "Offre" o ON c.offre_id = o.id
            JOIN "Etudiant" e ON c.etudiant_id = e.etudiant_id
            WHERE o.entreprise_id = $1
        `;
        const result = await query(sql, [entrepriseId]);
        res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Erreur récupération candidatures" });
    }
};

// 3. Accepter/Refuser (Décision Entreprise)
export const deciderCandidature = async (req: Request, res: Response) => {
    try {
        const { candidatureId, decision } = req.body; // 'RETENU' ou 'REFUSE' (selon ton ENUM SQL)

        const sql = `UPDATE "Candidature" SET statut = $1 WHERE id = $2 RETURNING *`;
        const result = await query(sql, [decision, candidatureId]);

        if (result.rowCount === 0) {
            return res.status(404).json({ error: "Candidature introuvable" });
        }

        res.status(200).json({ message: `Candidature mise à jour : ${decision}`, data: result.rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Erreur lors de la décision" });
    }
};