import express from 'express';
import { getProfile, updateRecherche, uploadCV, deleteCV } from '../controllers/etudiantController';

const router = express.Router();

// POST /api/etudiant/profile - Récupérer le profil
router.post('/profile', getProfile);

// PATCH /api/etudiant/recherche - Mettre à jour le statut de recherche
router.patch('/recherche', updateRecherche);

// POST /api/etudiant/cv - Déposer un CV
router.post('/cv', uploadCV);

// DELETE /api/etudiant/cv - Supprimer le CV
router.delete('/cv', deleteCV);

export default router;
