import express from 'express';
import { getPending, validate, refuseCandidature } from '../controllers/affectationController';

const router = express.Router();

// GET /api/affectations/pending - Liste des candidatures à valider
router.get('/pending', getPending);

// POST /api/affectations - Valider une candidature (créer l'affectation)
router.post('/', validate);

// POST /api/affectations/refuse - Refuser une candidature (refus pédagogique)
router.post('/refuse', refuseCandidature);

export default router;
