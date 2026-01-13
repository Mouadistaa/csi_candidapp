import { Request, Response } from 'express';
import { authenticate } from '../services/authService';
import { getClient } from '../config/db';

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
    }else if (user.role === 'ENTREPRISE') {
      redirectUrl = '/dashboard/entreprise'; 
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

export async function registerEntreprise(req: Request, res: Response) {
  const { raisonSociale, email, password, siret, adresse, ville, pays, siteWeb, contactNom } = req.body;

  // Validation
  if (!raisonSociale || !email || !password || !siret || !adresse || !ville || !pays || !contactNom) {
    return res.status(400).json({ error: 'MISSING_FIELDS' });
  }

  // Validation email
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({ error: 'INVALID_EMAIL' });
  }

  // Validation mot de passe (minimum 6 caractères)
  if (password.length < 6) {
    return res.status(400).json({ error: 'PASSWORD_TOO_SHORT' });
  }

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Vérifier si l'email existe déjà
    const existingUser = await client.query(
      'SELECT id FROM "Utilisateur" WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      await client.query('ROLLBACK');
      client.release();
      return res.status(409).json({ error: 'EMAIL_ALREADY_EXISTS' });
    }

    // Hacher le mot de passe (import dynamique comme dans authService)
    const bcryptModule: any = await import('bcrypt');
    const bcrypt = bcryptModule.default || bcryptModule;
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Créer l'utilisateur
    const userResult = await client.query(
  `INSERT INTO "Utilisateur" (email, password_hash, role, actif, nom)
   VALUES ($1, $2, $3, $4, $5)
   RETURNING id`,
  [email, passwordHash, 'ENTREPRISE', true, raisonSociale] // On utilise la raison sociale comme nom par défaut
);

    const userId = userResult.rows[0].id;

    // Créer l'entreprise (pays="France" par défaut comme requis par le modèle)
    await client.query(
      `INSERT INTO "Entreprise" 
       (utilisateur_id, raison_sociale, siret, adresse, ville, pays, site_web, contact_nom, contact_email)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        userId, 
        raisonSociale, 
        siret, 
        adresse, 
        ville, 
        pays, 
        siteWeb || null, // Si siteWeb est vide, on met NULL
        contactNom,
        email // On utilise l'email de connexion comme contact_email par défaut
      ]
    );

    await client.query('COMMIT');
    client.release();

    res.status(201).json({
      ok: true,
      message: 'Compte créé avec succès'
    });
  } catch (err: any) {
    await client.query('ROLLBACK');
    client.release();
    console.error('Erreur lors de l\'inscription:', err);

    // Gestion des erreurs de contrainte
    if (err.code === '23505') { // Violation de contrainte unique
      return res.status(409).json({ error: 'EMAIL_ALREADY_EXISTS' });
    }

    res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}
