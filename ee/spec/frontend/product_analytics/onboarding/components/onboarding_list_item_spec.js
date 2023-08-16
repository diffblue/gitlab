import OnboardingListItem from 'ee/product_analytics/onboarding/components/onboarding_list_item.vue';
import OnboardingState from 'ee/product_analytics/onboarding/components/onboarding_state.vue';
import AnalyticsFeatureListItem from 'ee/analytics/analytics_dashboards/components/list/feature_list_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import {
  STATE_CREATE_INSTANCE,
  STATE_LOADING_INSTANCE,
  STATE_WAITING_FOR_EVENTS,
} from 'ee/product_analytics/onboarding/constants';

import { TEST_PROJECT_FULL_PATH } from '../../mock_data';

describe('OnboardingListItem', () => {
  let wrapper;

  const findListItem = () => wrapper.findComponent(AnalyticsFeatureListItem);
  const findState = () => wrapper.findComponent(OnboardingState);

  const createWrapper = (state) => {
    wrapper = shallowMountExtended(OnboardingListItem, {
      provide: {
        namespaceFullPath: TEST_PROJECT_FULL_PATH,
      },
    });

    return findState().vm.$emit('change', state);
  };

  describe('default behaviour', () => {
    beforeEach(() => {
      return createWrapper(STATE_CREATE_INSTANCE);
    });

    it('renders the list item', () => {
      expect(findListItem().props()).toMatchObject({
        title: 'Product Analytics',
        description:
          'Set up to track how your product is performing and optimize your product and development processes.',
        badgeText: null,
        to: 'product-analytics-onboarding',
      });
    });

    describe('and the state is complete', () => {
      beforeEach(() => {
        return findState().vm.$emit('complete');
      });

      it('emits the complete event', () => {
        expect(wrapper.emitted('complete')).toEqual([[]]);
      });
    });

    describe('and the state emitted an error', () => {
      const error = new Error('error');

      beforeEach(() => {
        return findState().vm.$emit('error', error);
      });

      it('emits an error event with a message', () => {
        expect(wrapper.emitted('error')).toEqual([
          [error, true, 'An error occurred while fetching data. Refresh the page to try again.'],
        ]);
      });
    });
  });

  describe('badge text', () => {
    it.each`
      state                       | badgeText
      ${STATE_WAITING_FOR_EVENTS} | ${'Waiting for events'}
      ${STATE_LOADING_INSTANCE}   | ${'Loading instance'}
    `('renders "$badgeText" when the state is "$state"', async ({ state, badgeText }) => {
      await createWrapper(state);

      expect(findListItem().props('badgeText')).toBe(badgeText);
    });
  });
});
