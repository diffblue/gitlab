import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SecurityDashboardCard from 'ee/security_dashboard/components/shared/security_dashboard_card.vue';

describe('SecurityDashboardCard component', () => {
  let wrapper;

  // Finders
  const findTitle = () => wrapper.findByTestId('title');
  const findHelpText = () => wrapper.findByTestId('help-text');
  const findControls = () => wrapper.findByTestId('controls');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(SecurityDashboardCard, options);
  };

  it('renders the title', () => {
    const title = 'Card title';
    createComponent({
      slots: {
        title,
      },
    });

    expect(findTitle().text()).toBe(title);
  });

  it('renders the help text', () => {
    const helpText = 'Help text';
    createComponent({
      slots: {
        'help-text': helpText,
      },
    });

    expect(findHelpText().text()).toBe(helpText);
  });

  describe('controls slot', () => {
    it('does not render by default', () => {
      createComponent();

      expect(findControls().exists()).toBe(false);
    });

    it('renders controls if provided', () => {
      const controls = 'Card controls';
      createComponent({
        slots: {
          controls,
        },
      });

      expect(findControls().text()).toBe(controls);
    });
  });

  describe('loading state', () => {
    const content = 'Card body';
    const slots = {
      default: content,
    };

    it('renders a loading icon and hides the content when loading', () => {
      createComponent({
        propsData: {
          isLoading: true,
        },
        slots,
      });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(wrapper.text()).not.toContain(content);
    });

    it('renders the content and hides the loading icon when not loading', () => {
      createComponent({
        propsData: {
          isLoading: false,
        },
        slots,
      });

      expect(findLoadingIcon().exists()).toBe(false);
      expect(wrapper.text()).toContain(content);
    });
  });
});
