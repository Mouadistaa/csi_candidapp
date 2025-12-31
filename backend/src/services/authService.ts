import { query } from '../config/db';

export type AuthenticatedUser = {
  id: number;
  email: string;
  nom?: string | null;
  role: string;
};

export async function authenticate(email: string, password: string): Promise<AuthenticatedUser | null> {
  const res = await query('SELECT id, email, password_hash, role FROM "Utilisateur" WHERE email = $1 LIMIT 1', [email]);
  const row = res.rows[0];
  if (!row) return null;

  const hash: string | null = row.password_hash ?? null;
  if (!hash) return null;

  if (hash.startsWith('$2') || hash.startsWith('$argon')) {
    try {
      const bcryptModule: any = await import('bcrypt');
      const bcrypt = bcryptModule.default || bcryptModule;
      const ok: boolean = await bcrypt.compare(password, hash);
      if (!ok) return null;
    } catch (err) {
      console.warn('bcrypt not available, cannot verify hashed password');
      return null;
    }
  } else {
    if (password !== hash) return null;
  }

  return {
    id: row.id,
    email: row.email,
    nom: null,
    role: row.role,
  };
}
