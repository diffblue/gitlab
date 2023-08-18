import { shallowMount } from '@vue/test-utils';
import IssueCardTimeInfo from 'ee/issues/list/components/issue_card_time_info.vue';
import WeightCount from 'ee/issues/components/weight_count.vue';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import { WIDGET_TYPE_HEALTH_STATUS, WIDGET_TYPE_WEIGHT } from '~/work_items/constants';

describe('EE IssueCardTimeInfo component', () => {
  let wrapper;

  const issueObject = {
    weight: 2,
    healthStatus: 'onTrack',
  };

  const workItemObject = {
    widgets: [
      {
        type: WIDGET_TYPE_HEALTH_STATUS,
        healthStatus: 'onTrack',
      },
      {
        type: WIDGET_TYPE_WEIGHT,
        weight: 2,
      },
    ],
  };

  const findWeightCount = () => wrapper.findComponent(WeightCount);
  const findIssueHealthStatus = () => wrapper.findComponent(IssueHealthStatus);

  const mountComponent = ({ issue, hasIssuableHealthStatusFeature = false } = {}) =>
    shallowMount(IssueCardTimeInfo, {
      provide: { hasIssuableHealthStatusFeature },
      propsData: { issue },
    });

  describe.each`
    type           | obj
    ${'issue'}     | ${issueObject}
    ${'work item'} | ${workItemObject}
  `('with $type object', ({ obj }) => {
    describe('weight', () => {
      it('renders', () => {
        wrapper = mountComponent({ issue: obj });

        expect(findWeightCount().props('weight')).toBe(2);
      });
    });

    describe('health status', () => {
      describe('when hasIssuableHealthStatusFeature=true', () => {
        it('renders', () => {
          wrapper = mountComponent({ hasIssuableHealthStatusFeature: true, issue: obj });

          expect(findIssueHealthStatus().props('healthStatus')).toBe('onTrack');
        });
      });

      describe('when hasIssuableHealthStatusFeature=false', () => {
        it('does not render', () => {
          wrapper = mountComponent({ hasIssuableHealthStatusFeature: false, issue: obj });

          expect(findIssueHealthStatus().exists()).toBe(false);
        });
      });
    });
  });
});
