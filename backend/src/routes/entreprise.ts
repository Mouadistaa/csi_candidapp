import { Router } from 'express';
import * as entCtrl from '../controllers/entrepriseController';

const router = Router();

// 1. Dashboard KPIs
router.get('/stats', entCtrl.getStats);

// 2. Liste des offres de l'entreprise
router.get('/mes-offres', entCtrl.getMesOffres);

// 3. Liste des candidatures
router.get('/candidatures', entCtrl.getCandidaturesRecues);

// 4. Action de décision (Accepter/Refuser)
router.post('/candidature/decision', entCtrl.deciderCandidature);

// 5) Publier une offre (si tu ajoutes createOffre dans ton controller)
router.post('/offres', entCtrl.createOffre);

export default router;