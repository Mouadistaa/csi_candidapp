import express from 'express';
import path from 'path';
import { query } from './config/db';
import utilisateurRoutes from './routes/utilisateur';
import authRoutes from './routes/auth';
import offreRoutes from './routes/offre';

const app = express();
const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.use(express.json());

// API mount
app.use('/api/utilisateurs', utilisateurRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/offres', offreRoutes);

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
