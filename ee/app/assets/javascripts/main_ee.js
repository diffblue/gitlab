import 'bootstrap/js/dist/modal';
import initEETrialBanner from 'ee/ee_trial_banner';
import trackNavbarEvents from 'ee/event_tracking/navbar';
import initNamespaceStorageLimitAlert from 'ee/namespace_storage_limit_alert';
import initNamespaceUserCapReachedAlert from 'ee/namespace_user_cap_reached_alert';

if (document.querySelector('.js-verification-reminder') !== null) {
  // eslint-disable-next-line promise/catch-or-return
  import('ee/billings/verification_reminder').then(({ default: initVerificationReminder }) => {
    initVerificationReminder();
  });
}

// EE specific calls
initEETrialBanner();
initNamespaceStorageLimitAlert();
initNamespaceUserCapReachedAlert();

trackNavbarEvents();
