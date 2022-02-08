import api from '~/api';

export const SERVICE_PING_SETTINGS_CLICK_EVENT = 'users_clicking_registration_features_offer';

export const SERVICE_PING_SETTINGS_LINK_SELECTOR = '.js-go-to-service-ping-settings';

export function initServicePingSettingsClickTracking() {
  const triggers = document.querySelectorAll(SERVICE_PING_SETTINGS_LINK_SELECTOR);

  if (!triggers.length) {
    return;
  }

  triggers.forEach((trigger) => {
    trigger.addEventListener('click', () => {
      api.trackRedisCounterEvent(SERVICE_PING_SETTINGS_CLICK_EVENT);
    });
  });
}
