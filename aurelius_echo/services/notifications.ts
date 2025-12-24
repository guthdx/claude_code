
export const requestNotificationPermission = async (): Promise<boolean> => {
  if (!('Notification' in window)) {
    console.warn("This browser does not support notifications");
    return false;
  }
  
  try {
    const permission = await Notification.requestPermission();
    return permission === 'granted';
  } catch (e) {
    console.error("Error requesting notification permission", e);
    return false;
  }
};

export const getNotificationPermissionState = (): NotificationPermission => {
  if (!('Notification' in window)) return 'denied';
  return Notification.permission;
};

export const sendNotification = (title: string, body: string) => {
  if (!('Notification' in window)) return;
  
  if (Notification.permission === 'granted') {
    try {
      new Notification(title, {
        body,
        icon: '/icon.png', // Fallback, browsers often use the PWA icon
        tag: 'aurelius-quote', // Prevents stacking multiple quotes
        silent: false
      });
    } catch (e) {
      console.error("Failed to send notification", e);
    }
  }
};
