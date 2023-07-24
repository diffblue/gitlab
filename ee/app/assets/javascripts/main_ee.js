import initEETrialBanner from 'ee/ee_trial_banner';
import trackNavbarEvents from 'ee/event_tracking/navbar';
import initNamespaceUserCapReachedAlert from 'ee/namespace_user_cap_reached_alert';
import { initTanukiBotChatDrawer } from 'ee/ai/tanuki_bot';

if (document.querySelector('.js-verification-reminder') !== null) {
  // eslint-disable-next-line promise/catch-or-return
  import('ee/billings/verification_reminder').then(({ default: initVerificationReminder }) => {
    initVerificationReminder();
  });
}

// EE specific calls
initEETrialBanner();
initNamespaceUserCapReachedAlert();

trackNavbarEvents();
initTanukiBotChatDrawer();
