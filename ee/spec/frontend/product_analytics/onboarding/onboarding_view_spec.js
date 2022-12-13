import { GlEmptyState } from '@gitlab/ui';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';

describe('ProductAnalyticsOnboardingView', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createWrapper = () => {
    wrapper = shallowMountExtended(ProductAnalyticsOnboardingView, {
      provide: {
        chartEmptyStateIllustrationPath: TEST_HOST,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the empty state with expected props', () => {
      const emptyState = findEmptyState();

      expect(emptyState.props()).toMatchObject({
        title: ProductAnalyticsOnboardingView.i18n.title,
        svgPath: TEST_HOST,
        primaryButtonText: ProductAnalyticsOnboardingView.i18n.setUpBtnText,
        primaryButtonLink: '#',
        secondaryButtonText: ProductAnalyticsOnboardingView.i18n.learnMoreBtnText,
        secondaryButtonLink: ProductAnalyticsOnboardingView.docsPath,
      });
      expect(emptyState.text()).toContain(ProductAnalyticsOnboardingView.i18n.description);
    });
  });
});
