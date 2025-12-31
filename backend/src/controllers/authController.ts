import { Request, Response } from 'express';
import { authenticate } from '../services/authService';

export async function loginHandler(req: Request, res: Response) {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'MISSING_FIELDS' });

  try {
    const user = await authenticate(email, password);
    if (!user) return res.status(401).json({ error: 'INVALID_CREDENTIALS' });

    // REDIRECTION CONDITIONNELLE SELON LE RÔLE
    let redirectUrl = '/profile'; // Défaut étudiant

    if (user.role === 'ENSEIGNANT' || user.role === 'ADMIN') {
      redirectUrl = '/enseignant/dashboard';
    } else if (user.role === 'SECRETAIRE') {
      redirectUrl = '/secretaire/dashboard';
    }

    res.json({
      ok: true,
      user,
      redirectUrl
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

