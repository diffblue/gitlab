import { shallowMount } from '@vue/test-utils';
import GroupRepositoryAnalytics, {
  VISIT_EVENT_FEATURE_FLAG,
  VISIT_EVENT_NAME,
} from 'ee/analytics/repository_analytics/components/group_repository_analytics.vue';
import TestCoverageSummary from 'ee/analytics/repository_analytics/components/test_coverage_summary.vue';
import TestCoverageTable from 'ee/analytics/repository_analytics/components/test_coverage_table.vue';
import Api from '~/api';

jest.mock('~/api.js');

describe('Group repository analytics app', () => {
  let wrapper;

  const createComponent = (glFeatures = {}) => {
    wrapper = shallowMount(GroupRepositoryAnalytics, { provide: { glFeatures } });
  };

  describe('test coverage', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders coverage summary and coverage table components', () => {
      expect(wrapper.findComponent(TestCoverageSummary).exists()).toBe(true);
      expect(wrapper.findComponent(TestCoverageTable).exists()).toBe(true);
    });
  });

  describe('service ping events', () => {
    describe('with the feature flag enabled', () => {
      beforeEach(() => {
        createComponent({ [VISIT_EVENT_FEATURE_FLAG]: true });
      });

      it('tracks a visit event on mount', () => {
        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(VISIT_EVENT_NAME);
      });
    });
  });
});
