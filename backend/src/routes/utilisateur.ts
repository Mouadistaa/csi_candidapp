import express from 'express';
import { Request, Response } from 'express';
import { query } from '../config/db';

const router = express.Router();

router.get('/', async (_req: Request, res: Response) => {
    try {
        const result = await query('SELECT id, email, password_hash FROM "Utilisateur" ORDER BY id');
        res.json(result.rows);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'DB_ERROR' });
    }
});

export default router;