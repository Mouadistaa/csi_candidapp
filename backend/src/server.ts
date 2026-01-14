import express from 'express';
import path from 'path';
import { query } from './config/db';
import utilisateurRoutes from './routes/utilisateur';
import authRoutes from './routes/auth';
import offreRoutes from './routes/offre';
import enseignantRoutes from './routes/enseignant';
import secretaireRoutes from './routes/secretaire';
import candidatureRoutes from './routes/candidature';
import attestationRCRoutes from './routes/attestationRC';
import entrepriseRoutes from './routes/entreprise';

const app = express();
const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.use(express.json({limit: '10mb'}));

// API mount
app.use('/api/utilisateurs', utilisateurRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/offres', offreRoutes);
app.use('/api/enseignant', enseignantRoutes);
app.use('/api/dashboard/secretaire', secretaireRoutes);
app.use('/api/attestation-rc', attestationRCRoutes);
app.use('/api/candidatures', candidatureRoutes);
app.use('/api/entreprise', entrepriseRoutes); 

// --- ROUTES FRONTEND ---

app.get('/', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'accueil.html'));
});

app.get('/login', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'login.html'));
});

app.get('/register_entreprise.html', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'register_entreprise.html'));
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

// Routes Enseignant
app.get('/enseignant/dashboard', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'dashboard-enseignant.html'));
});

app.get('/enseignant/referentiel', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'referentiel.html'));
});

app.get('/enseignant/archives', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'archives.html'));
});

// Routes Secrétaire
app.get('/secretaire/dashboard', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'dashboard-secretaire.html'));
});

app.get('/secretaire/etudiants', (_req, res) => {
  res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'gestion-etudiants.html'));
});

app.get('/attestation-rc', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'attestation-rc.html'));
});

// === AJOUTS POUR LE MODULE ENTREPRISE (C'EST ICI QUE CA MANQUAIT) ===

// 1. Route pour le Dashboard Entreprise
app.get('/dashboard/entreprise', (_req, res) => {
    // Attention au nom du fichier : dashboard_entreprise.html (avec underscore)
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'dashboard_entreprise.html'));
});

// 2. Route pour créer une offre (le bouton existe sur le dashboard)
app.get('/create-offre', (_req, res) => {
    // Si tu n'as pas encore créé ce fichier, ça fera une erreur 404, mais la route est prête
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'create_offre.html'));
});

// ===================================================================

// 3. Route pour gérer les candidatures d'une offre (page Entreprise)
app.get('/entreprise/offres/:id/candidatures', (_req, res) => {
  res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'entreprise-offre-candidatures.html'));
});

// Serve frontend static files (CSS, JS, images, etc.)
app.use(express.static(path.join(__dirname, '..', '..', 'frontend'), { index: false }));

async function start() {
    try {
        const result = await query('SELECT NOW() AS now');
        console.log('DB OK:', result.rows[0]);
        // const tables = await query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' OR table_schema = 'm1user1_04';");
        // console.log('TABLES VISIBLES :', tables.rows);
    } catch (err) {
        console.error('DB ERROR:', err);
        process.exit(1);
    }

    app.listen(PORT, () => {
        console.log(`Server listening on port ${PORT}`);
    });
}

start();