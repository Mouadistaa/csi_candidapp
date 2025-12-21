import express from 'express';
import { query } from './config/db';

const app = express();
const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;

app.get('/', (_req, res) => res.send('Server running'));

async function start() {
    try {
        const result = await query('SELECT * FROM "Utilisateur"');
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