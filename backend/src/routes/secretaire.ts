import { Router } from 'express';
import * as secCtrl from '../controllers/secretaireController';

const router = Router();

// ==================== DASHBOARD SECRÉTAIRE ====================
router.get('/stats', secCtrl.getDashboardStats);

// ==================== ATTESTATIONS RC (100% via vues) ====================
// Liste (EN_ATTENTE)
router.get('/attestations', secCtrl.getAttestationsAValider);

// Valider / Refuser (action via vue + trigger)
router.post('/attestations/:etudiantId/valider', secCtrl.validerAttestationRC);
router.post('/attestations/:etudiantId/refuser', secCtrl.refuserAttestationRC);

// ==================== GESTION DES ÉTUDIANTS ====================
router.post('/etudiants', secCtrl.creerEtudiant);

export default router;
