import { Router } from 'express';
import { getDashboardStats } from '../controllers/secretaireController';

const router = Router();

// ==================== DASHBOARD SECRÉTAIRE ====================
router.get('/stats', getDashboardStats);

export default router;
