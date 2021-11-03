import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Security Configuration Page Layout component', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(ConfigurationPageLayout, {
      slots: {
        alert: 'Page alert',
        heading: 'Page title',
        actions: 'Action',
        description: 'Scanner description',
        default: '<div>form</div>',
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });
});
