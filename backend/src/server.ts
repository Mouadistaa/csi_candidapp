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

app.get('/attestation-rc', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'attestation-rc.html'));
});

// Serve frontend static files (CSS, JS, images, etc.)
app.use(express.static(path.join(__dirname, '..', '..', 'frontend'), { index: false }));

async function start() {
    try {
        const result = await query('SELECT NOW() AS now');
        console.log('DB OK:', result.rows[0]);
        const tables = await query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' OR table_schema = 'm1user1_04';");
        console.log('TABLES VISIBLES :', tables.rows);
    } catch (err) {
        console.error('DB ERROR:', err);
        process.exit(1);
    }

    app.listen(PORT, () => {
        console.log(`Server listening on port ${PORT}`);
    });
}

start();
