import { shallowMount } from '@vue/test-utils';
import SubscriptionPurchaseCard from 'ee/admin/subscriptions/show/components/subscription_purchase_card.vue';
import { buySubscriptionCard } from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('SubscriptionPurchaseCard', () => {
  let wrapper;
  const buySubscriptionPath = 'sample-buy-subscription-path';

  const findBuySubscriptionButton = () => wrapper.findByTestId('buy-subscription-button');

  const createComponent = () => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionPurchaseCard, {
        provide: {
          buySubscriptionPath,
        },
      }),
    );
  };

  describe('text and button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders card description', () => {
      expect(wrapper.text()).toContain(buySubscriptionCard.description);
    });

    it('has a buy subscription button', () => {
      expect(findBuySubscriptionButton().exists()).toBe(true);
      expect(findBuySubscriptionButton().attributes('href')).toBe(buySubscriptionPath);
    });
  });
});
