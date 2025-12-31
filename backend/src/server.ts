import express from 'express';
import path from 'path';
import { query } from './config/db';
import utilisateurRoutes from './routes/utilisateur';
import authRoutes from './routes/auth';
import offreRoutes from './routes/offre';
import enseignantRoutes from './routes/enseignant';
import secretaireRoutes from './routes/secretaire';

const app = express();
const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.use(express.json());

// API mount
app.use('/api/utilisateurs', utilisateurRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/offres', offreRoutes);
app.use('/api/enseignant', enseignantRoutes);
app.use('/api/dashboard/secretaire', secretaireRoutes);

// Route POST /api/candidatures - Postuler à une offre
app.post('/api/candidatures', async (req, res) => {
    const { offre_id, userId } = req.body;

    if (!offre_id) {
        return res.status(400).json({ ok: false, error: 'offre_id est requis' });
    }

    if (!userId) {
        return res.status(400).json({ ok: false, error: 'userId requis' });
    }

    try {
        // Insertion "write-only" - SANS clause RETURNING
        await query(
            'INSERT INTO v_action_postuler (offre_id, etudiant_id, source) VALUES ($1, $2, $3)',
            [offre_id, userId, 'Plateforme Web']
        );

        // Si aucune erreur, c'est un succès
        return res.status(200).json({ ok: true, message: 'Candidature envoyée avec succès' });

    } catch (error: any) {
        console.error('Erreur lors de la candidature:', error);

        // Détection d'erreur de duplicata (candidature active existante)
        // La vue v_action_postuler empêche de postuler si une candidature active (non ANNULE) existe
        if (error.code === '23505' || error.message?.includes('duplicate') || error.message?.includes('unique') || error.message?.includes('active')) {
            return res.status(409).json({ ok: false, error: 'Vous avez déjà une candidature active pour cette offre' });
        }

        // Autres erreurs
        return res.status(500).json({ ok: false, error: 'Erreur lors de la candidature' });
    }
});

// Route GET /api/mes-candidatures - Récupérer les candidatures de l'étudiant
// SÉCURISÉ : Requiert userId dans le corps de la requête
app.post('/api/mes-candidatures', async (req, res) => {
    const { userId, role } = req.body;

    // Validation de sécurité : L'utilisateur doit fournir son ID et être ETUDIANT
    if (!userId) {
        return res.status(400).json({
            ok: false,
            error: 'userId requis'
        });
    }

    // Protection : Si ce n'est pas un étudiant, refuser l'accès
    if (role !== 'ETUDIANT') {
        return res.status(403).json({
            ok: false,
            error: 'Accès interdit - Cette API est réservée aux étudiants'
        });
    }

    try {
        const result = await query(
            `SELECT 
                candidature_id, 
                date_candidature, 
                statut_candidature, 
                offre_titre, 
                entreprise_nom, 
                entreprise_ville, 
                statut_actuel_offre
            FROM v_mes_candidatures_etudiant
            WHERE utilisateur_id = $1
            ORDER BY date_candidature DESC`,
            [userId] // ID provenant de l'utilisateur authentifié
        );

        return res.status(200).json({
            ok: true,
            candidatures: result.rows
        });

    } catch (error: any) {
        console.error('Erreur lors de la récupération des candidatures:', error);
        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de la récupération des candidatures'
        });
    }
});

// Route POST /api/candidatures/annuler - Annuler une candidature
app.post('/api/candidatures/annuler', async (req, res) => {
    const { candidature_id, userId } = req.body;

    if (!candidature_id) {
        return res.status(400).json({ ok: false, error: 'candidature_id est requis' });
    }

    if (!userId) {
        return res.status(400).json({ ok: false, error: 'userId requis' });
    }

    try {
        // Utilisation de la vue d'action pour l'annulation
        await query(
            `UPDATE v_action_annuler_candidature 
            SET statut = 'ANNULE' 
            WHERE candidature_id = $1 AND etudiant_id = $2`,
            [candidature_id, userId] // Utilisation du userId authentifié
        );

        return res.status(200).json({
            ok: true,
            message: 'Candidature annulée avec succès'
        });

    } catch (error: any) {
        console.error('Erreur lors de l\'annulation:', error);

        // Si le trigger empêche l'annulation (statut non EN_ATTENTE)
        if (error.message?.includes('trigger') || error.message?.includes('constraint')) {
            return res.status(400).json({
                ok: false,
                error: 'Impossible d\'annuler cette candidature'
            });
        }

        return res.status(500).json({
            ok: false,
            error: 'Erreur lors de l\'annulation de la candidature'
        });
    }
});

app.get('/', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'accueil.html'));
});

app.get('/login', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'login.html'));
});

app.get('/profile', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'profile.html'));
});

app.get('/offres', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'offres.html'));
});

app.get('/offres/:id', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'offre-details.html'));
});

app.get('/candidatures', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'candidatures.html'));
});

app.get('/enseignant/dashboard', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'dashboard-enseignant.html'));
});

app.get('/enseignant/referentiel', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'referentiel.html'));
});

app.get('/enseignant/archives', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'archives.html'));
});

app.get('/secretaire/dashboard', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'dashboard-secretaire.html'));
});

// Serve frontend static files (CSS, JS, images, etc.)
app.use(express.static(path.join(__dirname, '..', '..', 'frontend'), { index: false }));

async function start() {
    try {
        const result = await query('SELECT NOW() AS now');
        console.log('DB OK:', result.rows[0]);
    } catch (err) {
        console.error('DB ERROR:', err);
        process.exit(1);
    }

    app.listen(PORT, () => {
        console.log(`Server listening on port ${PORT}`);
    });
}

start();
