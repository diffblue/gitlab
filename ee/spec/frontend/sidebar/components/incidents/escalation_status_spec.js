import { GlDropdownSectionHeader, GlPopover, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EscalationStatus from 'ee/sidebar/components/incidents/escalation_status.vue';
import { STATUS_TRIGGERED } from '~/sidebar/constants';

describe('EscalationStatus', () => {
  let wrapper;
  const showSpy = jest.fn();
  const hideSpy = jest.fn();

  function createComponent(glFeatures = {}) {
    wrapper = mountExtended(EscalationStatus, {
      propsData: {
        status: STATUS_TRIGGERED,
      },
      provide: {
        glFeatures: {
          escalationPolicies: true,
          ...glFeatures,
        },
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownHeaderComponent = () => wrapper.findComponent(GlDropdownSectionHeader);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLearnMoreLink = () => wrapper.findComponent(GlLink);
  const findInnerStatusComponent = () => wrapper.findComponent({ ref: 'escalationStatus' });
  const openPopover = async () => {
    await findPopover().vm.$emit('show');
    await nextTick();
  };
  const closePopover = async () => {
    await findPopover().vm.$emit('hide');
    await nextTick();
  };

  describe('help popover', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a popover', () => {
      expect(findPopover().props('title')).toBe('Assign paging status');
      expect(findPopover().text()).toContain('Setting the status');
    });

    it('shows the Learn More link', () => {
      expect(findLearnMoreLink().text()).toBe('Learn More.');
      expect(findLearnMoreLink().attributes('href')).toContain(
        'manage_incidents.html#change-status',
      );
    });

    it('prevents self from being removed from DOM when open', async () => {
      await openPopover();

      expect(findInnerStatusComponent().props('preventDropdownClose')).toBe(true);
    });

    it('allows self to be removed from DOM when closed', async () => {
      await openPopover();
      await closePopover();

      expect(findInnerStatusComponent().props('preventDropdownClose')).toBe(false);
    });
  });

  describe('dropdown', () => {
    it('forwards `show` calls to the child', () => {
      createComponent();

      findInnerStatusComponent().vm.show = showSpy;

      wrapper.vm.show();

      expect(showSpy).toHaveBeenCalled();
    });

    it('forwards `hide` calls to the child', () => {
      createComponent();

      findInnerStatusComponent().vm.hide = hideSpy;

      wrapper.vm.hide();

      expect(hideSpy).toHaveBeenCalled();
    });
  });

  describe('licensed features', () => {
    it('when licensed, renders the dropdown header', () => {
      createComponent();

      expect(findDropdownHeaderComponent().exists()).toBe(true);
    });

    it('when unlicensed, does not render the dropdown header', () => {
      createComponent({ escalationPolicies: false });

      expect(findDropdownHeaderComponent().exists()).toBe(false);
    });
  });
});
