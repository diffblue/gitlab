import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Security Configuration Page Layout component', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const { slots = {} } = options;
    wrapper = shallowMountExtended(ConfigurationPageLayout, {
      slots: {
        alert: 'Page alert',
        heading: 'Page title',
        description: 'Scanner description',
        default: '<div>form</div>',
        ...slots,
      },
      ...options,
    });
  };

  const findPageAlert = () => wrapper.findByTestId('configuration-page-alert');

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('page level alert', () => {
    it('should render correctly', () => {
      createComponent();
      expect(findPageAlert().exists()).toBe(true);
    });

    it('should be disabled when slot is not present', () => {
      createComponent({
        slots: {
          alert: '',
        },
      });
      expect(findPageAlert().exists()).toBe(false);
    });

    it('should be disabled after dismissal', async () => {
      createComponent();

      findPageAlert().vm.$emit('dismiss');
      await wrapper.vm.$nextTick();

      expect(findPageAlert().exists()).toBe(false);
    });
  });
});
