// =====================================================
// Module Notifications - CANDIDAPP
// =====================================================

(function() {
    'use strict';

    // Configuration
    const POLLING_INTERVAL = 30000; // 30 secondes
    const NOTIFICATIONS_LIMIT = 10;

    let pollingTimer = null;
    let isPolling = false;

    // =====================================================
    // Helpers
    // =====================================================

    function getUserId() {
        const user = JSON.parse(sessionStorage.getItem('user') || 'null');
        return user?.id || null;
    }

    function formatTimeAgo(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const diffMs = now - date;
        const diffSec = Math.floor(diffMs / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHour = Math.floor(diffMin / 60);
        const diffDay = Math.floor(diffHour / 24);

        if (diffSec < 60) return "À l'instant";
        if (diffMin < 60) return `Il y a ${diffMin} min`;
        if (diffHour < 24) return `Il y a ${diffHour}h`;
        if (diffDay < 7) return `Il y a ${diffDay}j`;
        return date.toLocaleDateString('fr-FR');
    }

    function getNotificationIcon(type) {
        const icons = {
            'OFFRE_SOUMISE': {
                bg: 'bg-blue-100',
                color: 'text-blue-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>'
            },
            'OFFRE_VALIDEE': {
                bg: 'bg-green-100',
                color: 'text-green-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>'
            },
            'OFFRE_REFUSEE': {
                bg: 'bg-red-100',
                color: 'text-red-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"/>'
            },
            'CANDIDATURE_RECUE': {
                bg: 'bg-purple-100',
                color: 'text-purple-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>'
            },
            'CANDIDATURE_ACCEPTEE': {
                bg: 'bg-green-100',
                color: 'text-green-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5"/>'
            },
            'CANDIDATURE_REJETEE': {
                bg: 'bg-red-100',
                color: 'text-red-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14H5.236a2 2 0 01-1.789-2.894l3.5-7A2 2 0 018.736 3h4.018a2 2 0 01.485.06l3.76.94m-7 10v5a2 2 0 002 2h.096c.5 0 .905-.405.905-.904 0-.715.211-1.413.608-2.008L17 13V4m-7 10h2m5-10h2a2 2 0 012 2v6a2 2 0 01-2 2h-2.5"/>'
            },
            'AFFECTATION_VALIDEE': {
                bg: 'bg-indigo-100',
                color: 'text-indigo-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"/>'
            },
            'RC_VALIDEE': {
                bg: 'bg-green-100',
                color: 'text-green-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>'
            },
            'RC_REFUSEE': {
                bg: 'bg-red-100',
                color: 'text-red-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.618 5.984A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016zM12 9v2m0 4h.01"/>'
            },
            'SYSTEME': {
                bg: 'bg-gray-100',
                color: 'text-gray-600',
                svg: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>'
            }
        };
        return icons[type] || icons['SYSTEME'];
    }

    // =====================================================
    // API Calls
    // =====================================================

    async function fetchNotificationCount() {
        const userId = getUserId();
        if (!userId) return { count: 0, total: 0 };

        try {
            const res = await fetch(`/api/notifications/count?userId=${userId}`);
            const data = await res.json();
            if (data.ok) {
                return { count: data.count, total: data.total };
            }
        } catch (err) {
            console.error('Erreur fetch notification count:', err);
        }
        return { count: 0, total: 0 };
    }

    async function fetchNotifications() {
        const userId = getUserId();
        if (!userId) return [];

        try {
            const res = await fetch(`/api/notifications?userId=${userId}&limit=${NOTIFICATIONS_LIMIT}`);
            const data = await res.json();
            if (data.ok) {
                return data.notifications;
            }
        } catch (err) {
            console.error('Erreur fetch notifications:', err);
        }
        return [];
    }

    async function markNotificationAsRead(notificationId) {
        const userId = getUserId();
        if (!userId) return false;

        try {
            const res = await fetch(`/api/notifications/${notificationId}/read?userId=${userId}`, {
                method: 'POST'
            });
            const data = await res.json();
            return data.ok;
        } catch (err) {
            console.error('Erreur mark as read:', err);
            return false;
        }
    }

    async function markAllNotificationsAsRead() {
        const userId = getUserId();
        if (!userId) return false;

        try {
            const res = await fetch(`/api/notifications/read-all?userId=${userId}`, {
                method: 'POST'
            });
            const data = await res.json();
            return data.ok;
        } catch (err) {
            console.error('Erreur mark all as read:', err);
            return false;
        }
    }

    // =====================================================
    // UI Updates
    // =====================================================

    function updateBadge(count) {
        const badge = document.getElementById('notifBadge');
        if (!badge) return;

        if (count > 0) {
            badge.textContent = count > 99 ? '99+' : count;
            badge.classList.remove('hidden');
        } else {
            badge.classList.add('hidden');
        }
    }

    function renderNotifications(notifications) {
        const list = document.getElementById('notifList');
        if (!list) return;

        if (notifications.length === 0) {
            list.innerHTML = `
                <div class="p-6 text-center text-gray-500">
                    <svg class="w-12 h-12 mx-auto text-gray-300 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                    </svg>
                    <p>Aucune notification</p>
                </div>
            `;
            return;
        }

        list.innerHTML = notifications.map(notif => {
            const icon = getNotificationIcon(notif.type);
            const timeAgo = formatTimeAgo(notif.created_at);
            const unreadClass = notif.lu ? '' : 'bg-primary-50';

            return `
                <div class="p-3 hover:bg-gray-50 cursor-pointer border-b border-gray-100 ${unreadClass}"
                     onclick="handleNotificationClick(${notif.notification_id}, '${notif.lien || ''}')">
                    <div class="flex items-start space-x-3">
                        <div class="flex-shrink-0 w-10 h-10 ${icon.bg} rounded-full flex items-center justify-center">
                            <svg class="w-5 h-5 ${icon.color}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                ${icon.svg}
                            </svg>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium text-gray-900 ${notif.lu ? '' : 'font-semibold'}">${notif.titre}</p>
                            <p class="text-sm text-gray-500 truncate">${notif.message}</p>
                            <p class="text-xs text-gray-400 mt-1">${timeAgo}</p>
                        </div>
                        ${!notif.lu ? '<div class="w-2 h-2 bg-primary-600 rounded-full flex-shrink-0"></div>' : ''}
                    </div>
                </div>
            `;
        }).join('');
    }

    // =====================================================
    // Panel Toggle
    // =====================================================

    window.toggleNotificationPanel = async function() {
        const panel = document.getElementById('notifPanel');
        if (!panel) return;

        const isHidden = panel.classList.contains('hidden');

        if (isHidden) {
            // Ouvrir le panel et charger les notifications
            panel.classList.remove('hidden');
            const notifications = await fetchNotifications();
            renderNotifications(notifications);
        } else {
            panel.classList.add('hidden');
        }
    };

    // Fermer le panel si on clique en dehors
    document.addEventListener('click', function(e) {
        const bell = document.getElementById('notificationBell');
        const panel = document.getElementById('notifPanel');
        if (bell && panel && !bell.contains(e.target)) {
            panel.classList.add('hidden');
        }
    });

    // =====================================================
    // Actions
    // =====================================================

    window.handleNotificationClick = async function(notificationId, lien) {
        await markNotificationAsRead(notificationId);
        await refreshNotifications();

        if (lien) {
            window.location.href = lien;
        }
    };

    window.markAllRead = async function() {
        await markAllNotificationsAsRead();
        await refreshNotifications();
        const notifications = await fetchNotifications();
        renderNotifications(notifications);
    };

    async function refreshNotifications() {
        const { count } = await fetchNotificationCount();
        updateBadge(count);
    }

    // =====================================================
    // Polling
    // =====================================================

    function startPolling() {
        if (isPolling) return;
        isPolling = true;

        // Premier appel immédiat
        refreshNotifications();

        // Polling régulier
        pollingTimer = setInterval(refreshNotifications, POLLING_INTERVAL);
    }

    function stopPolling() {
        if (pollingTimer) {
            clearInterval(pollingTimer);
            pollingTimer = null;
        }
        isPolling = false;
    }

    // =====================================================
    // Initialisation
    // =====================================================

    function init() {
        const userId = getUserId();
        if (!userId) return;

        // Vérifier que les éléments existent
        const bell = document.getElementById('notificationBell');
        if (!bell) return;

        // Démarrer le polling
        startPolling();

        // Arrêter le polling quand la page est cachée
        document.addEventListener('visibilitychange', function() {
            if (document.hidden) {
                stopPolling();
            } else {
                startPolling();
            }
        });
    }

    // Lancer l'init au chargement du DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

})();
