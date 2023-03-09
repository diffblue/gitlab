import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import SecurityTrainingPromoBanner from 'ee/security_dashboard/components/project/security_training_promo_banner.vue';
import { stubComponent } from 'helpers/stub_component';
import SecurityTrainingPromo from 'ee/vue_shared/security_reports/components/security_training_promo.vue';

const dismissSpy = jest.fn();
const trackCTAClickSpy = jest.fn();

const SECURITY_CONFIGURATION_PATH = 'foo/bar';
const PROJECT_FULL_PATH = 'namespace/project';
const MOCK_SLOT_PROPS = {
  buttonText: 'Enable security training',
  buttonLink: 'some/link',
  trackCTAClick: trackCTAClickSpy,
  dismiss: dismissSpy,
};

describe('Security training promo banner component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(SecurityTrainingPromoBanner, {
      provide: {
        projectFullPath: PROJECT_FULL_PATH,
        securityConfigurationPath: SECURITY_CONFIGURATION_PATH,
      },
      stubs: {
        SecurityTrainingPromo: stubComponent(SecurityTrainingPromo, {
          render() {
            return this.$scopedSlots.default(MOCK_SLOT_PROPS);
          },
        }),
      },
    });
  };

  const findSecurityTrainingPromo = () => wrapper.findComponent(SecurityTrainingPromo);
  const findBanner = () => wrapper.findComponent(GlBanner);

  beforeEach(() => {
    createWrapper();
  });

  describe('SecurityTrainingPromo', () => {
    it('renders the component with the correct props', () => {
      expect(findSecurityTrainingPromo().props()).toMatchObject({
        securityConfigurationPath: SECURITY_CONFIGURATION_PATH,
        projectFullPath: PROJECT_FULL_PATH,
      });
    });
  });

  describe('GlBanner', () => {
    it('renders the component with the correct props', () => {
      const { buttonText, buttonLink } = MOCK_SLOT_PROPS;
      const { title } = SecurityTrainingPromoBanner.i18n;

      expect(findBanner().props()).toMatchObject({
        variant: 'introduction',
        buttonText,
        buttonLink,
        title,
      });
    });

    it('should trigger the dismiss method when the banner is closed', () => {
      expect(dismissSpy).not.toHaveBeenCalled();

      findBanner().vm.$emit('close');

      expect(dismissSpy).toHaveBeenCalled();
    });

    it('should trigger the trackCTAClick method when the banner is clicked', () => {
      expect(trackCTAClickSpy).not.toHaveBeenCalled();

      findBanner().vm.$emit('primary');

      expect(trackCTAClickSpy).toHaveBeenCalled();
    });
  });
});
