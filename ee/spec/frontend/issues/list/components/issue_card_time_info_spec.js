import { shallowMount } from '@vue/test-utils';
import IssueCardTimeInfo from 'ee/issues/list/components/issue_card_time_info.vue';
import WeightCount from 'ee/issues/components/weight_count.vue';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';

describe('EE IssueCardTimeInfo component', () => {
  let wrapper;

  const issue = {
    weight: 2,
    healthStatus: 'onTrack',
  };

  const findWeightCount = () => wrapper.findComponent(WeightCount);
  const findIssueHealthStatus = () => wrapper.findComponent(IssueHealthStatus);

  const mountComponent = ({ hasIssuableHealthStatusFeature = false } = {}) =>
    shallowMount(IssueCardTimeInfo, {
      provide: { hasIssuableHealthStatusFeature },
      propsData: { issue },
    });

  describe('weight', () => {
    it('renders', () => {
      wrapper = mountComponent();

      expect(findWeightCount().props('weight')).toBe(issue.weight);
    });
  });

  describe('health status', () => {
    describe('when hasIssuableHealthStatusFeature=true', () => {
      it('renders', () => {
        wrapper = mountComponent({ hasIssuableHealthStatusFeature: true });

        expect(findIssueHealthStatus().props('healthStatus')).toBe(issue.healthStatus);
      });
    });

    describe('when hasIssuableHealthStatusFeature=false', () => {
      it('does not render', () => {
        wrapper = mountComponent({ hasIssuableHealthStatusFeature: false });

        expect(findIssueHealthStatus().exists()).toBe(false);
      });
    });
  });
});
