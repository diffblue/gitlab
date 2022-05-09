import {
  SERVICE_PING_SETTINGS_CLICK_EVENT,
  SERVICE_PING_SETTINGS_LINK_SELECTOR,
  initServicePingSettingsClickTracking,
} from 'ee/registration_features_discovery_message';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'spec/test_constants';
import api from '~/api';

describe('track settings link clicks', () => {
  const clickSettingsLink = () => {
    document.querySelectorAll(SERVICE_PING_SETTINGS_LINK_SELECTOR).forEach((button) => {
      button.click();
    });
  };

  beforeEach(() => {
    jest.spyOn(api, 'trackRedisCounterEvent').mockResolvedValue({ data: '' });
  });

  describe('when links are present', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <a class="js-go-to-service-ping-settings" href="${TEST_HOST}"></a>
        <a class="js-go-to-service-ping-settings" href="${TEST_HOST}"></a>
      `);

      initServicePingSettingsClickTracking();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('track RedisHLL events', () => {
      clickSettingsLink();

      expect(api.trackRedisCounterEvent).toHaveBeenCalledTimes(2);
      expect(api.trackRedisCounterEvent).toHaveBeenLastCalledWith(
        SERVICE_PING_SETTINGS_CLICK_EVENT,
      );
    });
  });
});
