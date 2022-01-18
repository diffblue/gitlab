import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import SecurityTrainingPromo from 'ee/security_dashboard/components/shared/security_training_promo.vue';

const SECURITY_CONFIGURATION_PATH = 'foo/bar';
const VULNERABILITY_MANAGEMENT_TAB_NAME = 'vulnerability-management';

describe('ee/security_dashboard/components/shared/security_training_promo.vue', () => {
  let wrapper;

  const createWrapper = () =>
    shallowMount(SecurityTrainingPromo, {
      provide: {
        securityConfigurationPath: SECURITY_CONFIGURATION_PATH,
      },
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findBanner = () => wrapper.findComponent(GlBanner);

  describe('banner', () => {
    it('should be an introduction that announces the security training feature', () => {
      expect(findBanner().props()).toMatchObject({
        variant: 'introduction',
        title: SecurityTrainingPromo.i18n.title,
        buttonText: SecurityTrainingPromo.i18n.buttonText,
      });
      expect(findBanner().text()).toBe(SecurityTrainingPromo.i18n.content);
    });

    it(`should link to the security configuration's vulnerability management tab`, () => {
      expect(findBanner().props('buttonLink')).toBe(
        `${SECURITY_CONFIGURATION_PATH}?tab=${VULNERABILITY_MANAGEMENT_TAB_NAME}`,
      );
    });
  });
});
