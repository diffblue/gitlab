import { GlTooltip } from '@gitlab/ui';
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

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when no statuses are assigned', () => {
    it('hasHealthStatus computed property returns false', () => {
      expect(wrapper.vm.hasHealthStatus).toBe(false);
    });

    it('does not render health labels', () => {
      const longLabels = wrapper.findAll('.health-label-long');
      const shortLabels = wrapper.findAll('.health-label-short');

      expect(longLabels).toHaveLength(0);
      expect(shortLabels).toHaveLength(0);
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

    it('renders tooltip', () => {
      const tooltip = wrapper.findComponent(GlTooltip);

      expect(tooltip.exists()).toBe(true);
    });

    it('hasHealthStatus computed property returns false', () => {
      expect(wrapper.vm.hasHealthStatus).toBe(true);
    });

    it('renders label with both short and long text', () => {
      const longLabels = wrapper.findAll('.health-label-long');
      const shortLabels = wrapper.findAll('.health-label-short');

      expect(longLabels).toHaveLength(3);
      expect(shortLabels).toHaveLength(3);

      const expectedLongLabels = ['issues on track', 'issues need attention', 'issues at risk'];

      expect(longLabels).toHaveLength(expectedLongLabels.length);

      longLabels.wrappers.forEach((longLabelWrapper, index) => {
        expect(longLabelWrapper.text()).toEqual(expectedLongLabels[index]);
      });

      const expectedShortLabels = ['on track', 'need attention', 'at risk'];

      expect(shortLabels).toHaveLength(expectedShortLabels.length);

      shortLabels.wrappers.forEach((shortLabelWrapper, index) => {
        expect(shortLabelWrapper.text()).toEqual(expectedShortLabels[index]);
      });
    });
  });
});
