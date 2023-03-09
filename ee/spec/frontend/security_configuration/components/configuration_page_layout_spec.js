import { within } from '@testing-library/dom';
import ConfigurationPageLayout from 'ee/security_configuration/components/configuration_page_layout.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Security Configuration Page Layout component', () => {
  let wrapper;

  const withinComponent = () => within(wrapper.element);
  const findHeader = () => withinComponent().getByRole('banner');

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

  it('matches the snapshot', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('border', () => {
    const borderClasses = 'gl-mb-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid';

    it('adds border classes by default', () => {
      createComponent();

      expect(findHeader().className).toContain(borderClasses);
    });

    it('does not add border classes if no-border is true', () => {
      createComponent({
        propsData: {
          noBorder: true,
        },
      });

      expect(findHeader().className).not.toContain(borderClasses);
    });
  });
});
