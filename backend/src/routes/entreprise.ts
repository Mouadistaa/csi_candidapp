import { Router } from 'express';
import * as entCtrl from '../controllers/entrepriseController';
const router = Router();

router.get('/offres', entCtrl.getMesOffres);
router.get('/candidatures', entCtrl.getCandidaturesRecues);
router.post('/decision', entCtrl.deciderCandidature);

export default router;