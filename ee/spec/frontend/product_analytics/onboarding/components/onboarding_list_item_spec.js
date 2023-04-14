import OnboardingListItem from 'ee/product_analytics/onboarding/components/onboarding_list_item.vue';
import OnboardingState from 'ee/product_analytics/onboarding/components/onboarding_state.vue';
import AnalyticsFeatureListItem from 'ee/analytics/analytics_dashboards/components/list/feature_list_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import {
  FETCH_ERROR_MESSAGE,
  ONBOARDING_LIST_ITEM_I18N,
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
        projectFullPath: TEST_PROJECT_FULL_PATH,
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
        title: ONBOARDING_LIST_ITEM_I18N.title,
        description: ONBOARDING_LIST_ITEM_I18N.description,
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
        expect(wrapper.emitted('error')).toEqual([[error, true, FETCH_ERROR_MESSAGE]]);
      });
    });
  });

  describe('badge text', () => {
    it.each`
      state                       | badgeText
      ${STATE_WAITING_FOR_EVENTS} | ${ONBOARDING_LIST_ITEM_I18N.waitingForEvents}
      ${STATE_LOADING_INSTANCE}   | ${ONBOARDING_LIST_ITEM_I18N.loadingInstance}
    `('renders "$badgeText" when the state is "$state"', async ({ state, badgeText }) => {
      await createWrapper(state);

      expect(findListItem().props('badgeText')).toBe(badgeText);
    });
  });
});
