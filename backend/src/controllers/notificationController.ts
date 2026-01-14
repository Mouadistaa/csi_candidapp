import { Request, Response } from 'express';
import { query } from '../config/db';
import { Notification, NotificationCount } from '../types/Notification';

// GET /api/notifications - Liste les notifications
export async function getNotifications(req: Request, res: Response) {
    const userId = req.query.userId as string;
    const limit = parseInt(req.query.limit as string) || 20;
    const offset = parseInt(req.query.offset as string) || 0;
    const unreadOnly = req.query.unread === 'true';

    if (!userId) {
        return res.status(400).json({ ok: false, error: 'USER_ID_REQUIRED' });
    }

    try {
        let sql = `
            SELECT notification_id, type, titre, message, lien, entite_type, entite_id, lu, created_at, destinataire_id
            FROM v_mes_notifications
            WHERE destinataire_id = $1
        `;
        const params: (string | number | boolean)[] = [userId];

        if (unreadOnly) {
            sql += ` AND lu = false`;
        }

        sql += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
        params.push(limit, offset);

        const result = await query<Notification>(sql, params);

        return res.json({ ok: true, notifications: result.rows });
    } catch (err) {
        console.error('Erreur getNotifications:', err);
        return res.status(500).json({ ok: false, error: 'DB_ERROR' });
    }
}

// GET /api/notifications/count - Retourne le nombre de notifications
export async function getNotificationCount(req: Request, res: Response) {
    const userId = req.query.userId as string;

    if (!userId) {
        return res.status(400).json({ ok: false, error: 'USER_ID_REQUIRED' });
    }

    try {
        const result = await query<NotificationCount>(
            `SELECT non_lues, total FROM v_notifications_count WHERE destinataire_id = $1`,
            [userId]
        );

        if (result.rows.length === 0) {
            return res.json({ ok: true, count: 0, total: 0 });
        }

        const { non_lues, total } = result.rows[0];
        return res.json({ ok: true, count: non_lues, total });
    } catch (err) {
        console.error('Erreur getNotificationCount:', err);
        return res.status(500).json({ ok: false, error: 'DB_ERROR' });
    }
}

// POST /api/notifications/:id/read - Marque une notification comme lue
export async function markAsRead(req: Request, res: Response) {
    const notificationId = req.params.id;
    const userId = req.query.userId as string || req.body.userId;

    if (!userId) {
        return res.status(400).json({ ok: false, error: 'USER_ID_REQUIRED' });
    }

    if (!notificationId) {
        return res.status(400).json({ ok: false, error: 'NOTIFICATION_ID_REQUIRED' });
    }

    try {
        const result = await query(
            `UPDATE v_action_marquer_notification_lue SET lu = true WHERE notification_id = $1 AND destinataire_id = $2`,
            [notificationId, userId]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ ok: false, error: 'NOTIFICATION_NOT_FOUND' });
        }

        return res.json({ ok: true });
    } catch (err) {
        console.error('Erreur markAsRead:', err);
        return res.status(500).json({ ok: false, error: 'DB_ERROR' });
    }
}

// POST /api/notifications/read-all - Marque toutes les notifications comme lues
export async function markAllAsRead(req: Request, res: Response) {
    const userId = req.query.userId as string || req.body.userId;

    if (!userId) {
        return res.status(400).json({ ok: false, error: 'USER_ID_REQUIRED' });
    }

    try {
        await query(
            `UPDATE v_action_marquer_notification_lue SET lu = true WHERE destinataire_id = $1 AND lu = false`,
            [userId]
        );

        return res.json({ ok: true });
    } catch (err) {
        console.error('Erreur markAllAsRead:', err);
        return res.status(500).json({ ok: false, error: 'DB_ERROR' });
    }
}
