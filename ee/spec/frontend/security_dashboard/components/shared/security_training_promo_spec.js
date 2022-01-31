import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import SecurityTrainingPromo from 'ee/security_dashboard/components/shared/security_training_promo.vue';

const SECURITY_CONFIGURATION_PATH = 'foo/bar';
const VULNERABILITY_MANAGEMENT_TAB_NAME = 'vulnerability-management';

describe('Security training promo component', () => {
  let wrapper;
  const userCalloutDismissSpy = jest.fn();

  const createWrapper = ({ shouldShowCallout = true } = {}) =>
    shallowMount(SecurityTrainingPromo, {
      provide: {
        securityConfigurationPath: SECURITY_CONFIGURATION_PATH,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  const findBanner = () => wrapper.findComponent(GlBanner);

  describe('banner', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should be an introduction that announces the security training feature', () => {
      const { title, buttonText, content } = SecurityTrainingPromo.i18n;

      expect(findBanner().props()).toMatchObject({
        variant: 'introduction',
        title,
        buttonText,
      });
      expect(findBanner().text()).toBe(content);
    });

    it(`should link to the security configuration's vulnerability management tab`, () => {
      expect(findBanner().props('buttonLink')).toBe(
        `${SECURITY_CONFIGURATION_PATH}?tab=${VULNERABILITY_MANAGEMENT_TAB_NAME}`,
      );
    });
  });

  describe('dismissal', () => {
    it('should dismiss the callout when the banner is closed', () => {
      wrapper = createWrapper();

      expect(userCalloutDismissSpy).not.toHaveBeenCalled();

      findBanner().vm.$emit('close');

      expect(userCalloutDismissSpy).toHaveBeenCalled();
    });

    it('should not show the banner once it has been dismissed', () => {
      wrapper = createWrapper({ shouldShowCallout: false });

      expect(findBanner().exists()).toBe(false);
    });
  });
});
