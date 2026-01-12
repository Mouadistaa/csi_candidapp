import { Router } from 'express';
import * as secCtrl from '../controllers/secretaireController';

const router = Router();

// ==================== DASHBOARD SECRÉTAIRE ====================
router.get('/stats', secCtrl.getDashboardStats);

// Gestion des Attestations
router.get('/attestations', secCtrl.getAttestationsAValider);
router.post('/valider-rc', secCtrl.validerAttestation);

// Gestion des Étudiants
router.post('/etudiants', secCtrl.creerEtudiant);

export default router;
