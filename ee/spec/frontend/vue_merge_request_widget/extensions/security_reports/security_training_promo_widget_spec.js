import { GlIcon } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import SecurityTrainingPromo from 'ee/vue_shared/security_reports/components/security_training_promo.vue';
import SecurityTraininPromoWidget from 'ee/vue_merge_request_widget/extensions/security_reports/security_training_promo_widget.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

const dismissSpy = jest.fn();
const trackCTAClickSpy = jest.fn();

const SECURITY_CONFIGURATION_PATH = '/help/user/application_security/index.md';
const PROJECT_FULL_PATH = 'namespace/project';
const MOCK_SLOT_PROPS = {
  buttonText: 'Enable security training',
  buttonLink: 'some/link',
  trackCTAClick: trackCTAClickSpy,
  dismiss: dismissSpy,
};

describe('Security training promo widget component', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMountExtended(SecurityTraininPromoWidget, {
      propsData: {
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
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findEnableButton = () => wrapper.findByTestId('enableButton');
  const findCancelButton = () => wrapper.findByTestId('cancelButton');

  beforeEach(() => {
    createWrapper();
  });

  describe('SecurityTrainingPromo', () => {
    it('renders the component with the correct props', () => {
      expect(findSecurityTrainingPromo().props()).toEqual({
        securityConfigurationPath: SECURITY_CONFIGURATION_PATH,
        projectFullPath: PROJECT_FULL_PATH,
      });
    });
  });

  it('renders the title', () => {
    expect(wrapper.findByText('Resolve with security training').exists()).toBe(true);
  });

  it('renders the description', () => {
    expect(
      wrapper
        .findByText(
          'Enable security training to learn how to fix vulnerabilities. View security training from selected educational providers relevant to the detected vulnerability.',
        )
        .exists(),
    ).toBe(true);
  });

  it('renders the icons', () => {
    expect(findIcon().props()).toMatchObject({
      name: 'bulb',
      size: 16,
    });
  });

  describe('enable button', () => {
    it('renders the component with the correct props', () => {
      expect(findEnableButton().props()).toMatchObject({
        category: 'primary',
        variant: 'confirm',
      });
    });

    it('renders the correct text', () => {
      expect(findEnableButton().text()).toBe(MOCK_SLOT_PROPS.buttonText);
    });

    it('renders the correct link', () => {
      expect(findEnableButton().attributes('href')).toBe(MOCK_SLOT_PROPS.buttonLink);
    });

    it('should trigger the trackCTAClick method when it is clicked', () => {
      expect(trackCTAClickSpy).not.toHaveBeenCalled();

      findEnableButton().vm.$emit('click');

      expect(trackCTAClickSpy).toHaveBeenCalled();
    });
  });

  describe('cancel button', () => {
    it('renders the component with the correct props', () => {
      expect(findCancelButton().props()).toMatchObject({
        category: 'secondary',
      });
    });

    it('renders the correct text', () => {
      expect(findCancelButton().text()).toBe("Don't show again");
    });

    it('should trigger the dismiss method when it is clicked', () => {
      expect(dismissSpy).not.toHaveBeenCalled();

      findCancelButton().vm.$emit('click');

      expect(dismissSpy).toHaveBeenCalled();
    });
  });
});
