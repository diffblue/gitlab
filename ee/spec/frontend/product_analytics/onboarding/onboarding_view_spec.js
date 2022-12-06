import { shallowMount } from '@vue/test-utils';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import { s__ } from '~/locale';

describe('ProductAnalyticsOnboardingView', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(ProductAnalyticsOnboardingView);
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render', () => {
      expect(wrapper.text()).toBe(s__('Product Analytics|Onboarding view'));
    });
  });
});
