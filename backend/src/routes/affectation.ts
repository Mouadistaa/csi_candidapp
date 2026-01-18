import express from 'express';
import { getPending, validerAffectation, refuserAffectation } from '../controllers/affectationController';

const router = express.Router();

// GET /api/affectations/pending - Liste des candidatures à valider
router.get('/pending', getPending);

// POST /api/affectations - Valider une candidature (créer l'affectation)
router.post('/', validerAffectation);

// POST /api/affectations/refuse - Refuser une candidature (refus pédagogique)
router.post('/refuse', refuserAffectation);

export default router;
