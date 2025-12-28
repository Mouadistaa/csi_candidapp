import express from 'express';
import { getOffresHandler, getOffreByIdHandler } from '../controllers/offreController';

const router = express.Router();

// GET /api/offres - Récupérer toutes les offres
router.get('/', getOffresHandler);

// GET /api/offres/:id - Récupérer une offre spécifique
router.get('/:id', getOffreByIdHandler);

export default router;
