import { Request, Response } from 'express';
import { query, getClient } from '../config/db'; 
import * as bcrypt from 'bcrypt'; // Pour hacher le mot de passe

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

// Liste des attestations à valider
export const getAttestationsAValider = async (_req: Request, res: Response) => {
    try {
        const sql = `
            SELECT a.etudiant_id, e.nom, e.prenom, a.fichier_url, a.date_depot, a.statut
            FROM "AttestationRC" a
            JOIN "Etudiant" e ON a.etudiant_id = e.etudiant_id
            WHERE a.statut = 'EN_ATTENTE'
        `;
        const result = await query(sql);
        res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Erreur chargement attestations" });
    }
};

// Valider ou Refuser une attestation
export const validerAttestation = async (req: Request, res: Response) => {
    try {
        const { etudiantId, decision } = req.body; // decision: 'VALIDE' ou 'REFUSE'
        
        const sql = `
            UPDATE "AttestationRC" 
            SET statut = $1, date_validation = CURRENT_DATE 
            WHERE etudiant_id = $2 
            RETURNING *
        `;
        
        const result = await query(sql, [decision, etudiantId]);
        res.status(200).json({ ok: true, message: `Statut mis à jour : ${decision}` });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Erreur validation RC" });
    }
};

// ==================== CRÉATION ÉTUDIANT ====================

// POST /api/dashboard/secretaire/etudiants
export const creerEtudiant = async (req: Request, res: Response) => {
    const { nom, prenom, email, password, formation, promo } = req.body;

    // 1. Validation basique
    if (!nom || !prenom || !email || !password || !formation) {
        return res.status(400).json({ error: "Tous les champs sont obligatoires" });
    }

    const client = await getClient();

    try {
        await client.query('BEGIN'); // Début de la transaction

        // 2. Vérifier si l'email existe déjà
        const checkEmail = await client.query('SELECT id FROM "Utilisateur" WHERE email = $1', [email]);
        if (checkEmail.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: "Cet email est déjà utilisé" });
        }

        // 3. Hacher le mot de passe
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(password, saltRounds);

        // 4. Créer le compte UTILISATEUR (Login)
        const userQuery = `
            INSERT INTO "Utilisateur" (email, password_hash, role, actif, nom)
            VALUES ($1, $2, 'ETUDIANT', true, $3)
            RETURNING id
        `;
        const userRes = await client.query(userQuery, [email, passwordHash, nom]);
        const newUserId = userRes.rows[0].id;

        // 5. Créer le profil ÉTUDIANT (Métier)
        const etudiantQuery = `
            INSERT INTO "Etudiant" (utilisateur_id, nom, prenom, formation, promo, en_recherche)
            VALUES ($1, $2, $3, $4, $5, true)
            RETURNING etudiant_id
        `;
        await client.query(etudiantQuery, [newUserId, nom, prenom, formation, promo]);

        await client.query('COMMIT'); // Valider la transaction

        res.status(201).json({ 
            ok: true, 
            message: "Compte étudiant créé avec succès",
            id: newUserId 
        });

    } catch (error) {
        await client.query('ROLLBACK'); // Annuler si erreur
        console.error("Erreur création étudiant:", error);
        res.status(500).json({ error: "Erreur lors de la création de l'étudiant" });
    } finally {
        client.release(); // Libérer la connexion
    }
};