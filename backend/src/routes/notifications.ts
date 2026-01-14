import { Router } from 'express';
import * as notifCtrl from '../controllers/notificationController';

const router = Router();

router.get('/', notifCtrl.getNotifications);
router.get('/count', notifCtrl.getNotificationCount);
router.post('/:id/read', notifCtrl.markAsRead);
router.post('/read-all', notifCtrl.markAllAsRead);

export default router;
