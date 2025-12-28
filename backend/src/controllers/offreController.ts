import { Request, Response } from 'express';
import { query } from '../config/db';
import { OffreVisible } from '../types/Offre';

/**
 * Controller pour récupérer toutes les offres visibles
 * @route GET /api/offres
 */
export async function getOffresHandler(req: Request, res: Response) {
  try {
    const result = await query('SELECT * FROM v_offres_visibles_etudiant ORDER BY date_debut DESC');
    const offres: OffreVisible[] = result.rows;
    
    res.json({ ok: true, offres });
  } catch (err) {
    console.error('Erreur lors de la récupération des offres:', err);
    res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}

/**
 * Controller pour récupérer une offre par son ID
 * @route GET /api/offres/:id
 */
export async function getOffreByIdHandler(req: Request, res: Response) {
  const { id } = req.params;
  
  if (!id || isNaN(Number(id))) {
    return res.status(400).json({ error: 'INVALID_ID' });
  }

  try {
    const result = await query(
      'SELECT * FROM v_offres_visibles_etudiant WHERE offre_id = $1',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'OFFRE_NOT_FOUND' });
    }

    const offre: OffreVisible = result.rows[0];
    res.json({ ok: true, offre });
  } catch (err) {
    console.error('Erreur lors de la récupération de l\'offre:', err);
    res.status(500).json({ error: 'INTERNAL_ERROR' });
  }
}
