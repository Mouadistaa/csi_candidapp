import express from 'express';
import { getPending, validate } from '../controllers/affectationController';

const router = express.Router();

// GET /api/affectations/pending - Liste des candidatures à valider
router.get('/pending', getPending);

// POST /api/affectations - Valider une candidature (créer l'affectation)
router.post('/', validate);

export default router;
