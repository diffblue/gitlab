import { shallowMount } from '@vue/test-utils';
import DownloadTestCoverage from 'ee/analytics/repository_analytics/components/download_test_coverage.vue';
import GroupRepositoryAnalytics, {
  VISIT_EVENT_FEATURE_FLAG,
  VISIT_EVENT_NAME,
} from 'ee/analytics/repository_analytics/components/group_repository_analytics.vue';
import Api from '~/api';

jest.mock('~/api.js');

describe('Group repository analytics app', () => {
  let wrapper;

  const createComponent = (glFeatures = {}) => {
    wrapper = shallowMount(GroupRepositoryAnalytics, { provide: { glFeatures } });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('test coverage', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders test coverage header', () => {
      const header = wrapper.find('[data-testid="test-coverage-header"]');

      expect(header.exists()).toBe(true);
    });

    it('renders the download test coverage component', () => {
      expect(wrapper.findComponent(DownloadTestCoverage).exists()).toBe(true);
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
