import express from 'express';
import { loginHandler, registerEntreprise } from '../controllers/authController';

const router = express.Router();

router.post('/login', loginHandler);
router.post('/register-entreprise', registerEntreprise);

export default router;

