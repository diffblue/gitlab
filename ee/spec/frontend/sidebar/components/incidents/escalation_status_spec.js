import { GlDropdownSectionHeader, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EscalationStatus from 'ee/sidebar/components/incidents/escalation_status.vue';
import { STATUS_TRIGGERED } from '~/sidebar/components/incidents/constants';

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
  const findInnerStatusComponent = () => wrapper.findComponent({ ref: 'escalationStatus' });

  describe('popover', () => {
    it('renders a popover', () => {
      createComponent();

      expect(findPopover().props('title')).toBe('Assign paging status');
      expect(findPopover().attributes('content')).toContain('Setting the status');
    });

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
