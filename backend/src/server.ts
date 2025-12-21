import express from 'express';
import path from 'path';
import { query } from './config/db';
import utilisateurRoutes from './routes/utilisateur';

const app = express();
const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.use(express.json());

// API mount
app.use('/api/utilisateurs', utilisateurRoutes);

app.use(express.static(path.join(__dirname, '..', '..', 'frontend')));

app.get('/', (_req, res) => {
    res.sendFile(path.join(__dirname, '..', '..', 'frontend', 'index.html'));
});

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