import { GlPopover, GlAlert, GlBadge } from '@gitlab/ui';

import { shallowMount } from '@vue/test-utils';

import EpicHealthStatus from 'ee/related_items_tree/components/epic_health_status.vue';
import { mockEpic1 } from '../mock_data';

const createComponent = ({ healthStatus = mockEpic1.healthStatus } = {}) => {
  return shallowMount(EpicHealthStatus, {
    propsData: {
      healthStatus,
    },
  });
};

describe('EpicHealthStatus', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('when no statuses are assigned', () => {
    it('hasHealthStatus computed property returns false', () => {
      expect(wrapper.vm.hasHealthStatus).toBe(false);
    });

    it('does not render health labels', () => {
      expect(wrapper.findAllComponents(GlBadge)).toHaveLength(0);
    });
  });

  describe('when statuses are assigned', () => {
    beforeEach(() => {
      wrapper = createComponent({
        healthStatus: {
          issuesOnTrack: 1,
          issuesNeedingAttention: 0,
          issuesAtRisk: 0,
        },
      });
    });

    it('renders popover', () => {
      const popover = wrapper.findComponent(GlPopover);

      expect(popover.exists()).toBe(true);
    });

    it('hasHealthStatus computed property returns false', () => {
      expect(wrapper.vm.hasHealthStatus).toBe(true);
    });

    it('renders badges', () => {
      const badges = wrapper.findAllComponents(GlBadge);

      expect(badges).toHaveLength(3);

      const expectedVariants = ['success', 'warning', 'danger'];

      badges.wrappers.forEach((badge, index) => {
        expect(badge.attributes('variant')).toBe(expectedVariants[index]);
      });
    });

    it('displays warning', () => {
      expect(wrapper.findComponent(GlAlert).text()).toBe(
        'Counts reflect children you may not have access to.',
      );
    });
  });
});
