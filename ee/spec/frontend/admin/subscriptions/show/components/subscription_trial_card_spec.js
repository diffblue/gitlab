import { shallowMount } from '@vue/test-utils';
import SubscriptionTrialCard from 'ee/admin/subscriptions/show/components/subscription_trial_card.vue';
import { trialCard } from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('SubscriptionTrialCard', () => {
  let wrapper;
  const freeTrialPath = 'sample-free-trial-path';

  const findFreeTrialButton = () => wrapper.findByTestId('free-trial-button');

  const createComponent = () => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionTrialCard, {
        provide: {
          freeTrialPath,
        },
      }),
    );
  };

  describe('text and button', () => {
    beforeEach(() => {
      createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders card description', () => {
      expect(wrapper.text()).toContain(trialCard.description);
    });

    it('has a free trial button', () => {
      expect(findFreeTrialButton().exists()).toBe(true);
      expect(findFreeTrialButton().attributes('href')).toBe(freeTrialPath);
    });
  });
});
