import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatisticsSeatsCard from 'ee/usage_quotas/components/statistics_seats_card.vue';

describe('StatisticsSeatsCard', () => {
  let wrapper;
  const purchaseButtonLink = 'https://gitlab.com/purchase-more-seats';
  const defaultProps = {
    seatsUsed: 20,
    seatsOwed: 5,
    purchaseButtonLink,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StatisticsSeatsCard, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findSeatsUsedBlock = () => wrapper.findByTestId('seats-used-block');
  const findSeatsOwedBlock = () => wrapper.findByTestId('seats-owed-block');
  const findPurchaseButton = () => wrapper.findByTestId('purchase-button');

  describe('seats used block', () => {
    it('renders seats used block if seatsUsed is passed', () => {
      createComponent();

      const seatsUsedBlock = findSeatsUsedBlock();

      expect(seatsUsedBlock.exists()).toBe(true);
      expect(seatsUsedBlock.text()).toContain('20');
      expect(seatsUsedBlock.findComponent(GlLink).exists()).toBe(true);
    });

    it('does not render seats used block if seatsUsed is not passed', () => {
      createComponent({ seatsUsed: null });

      expect(findSeatsUsedBlock().exists()).toBe(false);
    });
  });

  describe('seats owed block', () => {
    it('renders seats owed block if seatsOwed is passed', () => {
      createComponent();

      const seatsOwedBlock = findSeatsOwedBlock();

      expect(seatsOwedBlock.exists()).toBe(true);
      expect(seatsOwedBlock.text()).toContain('5');
      expect(seatsOwedBlock.findComponent(GlLink).exists()).toBe(true);
    });

    it('does not render seats owed block if seatsOwed is not passed', () => {
      createComponent({ seatsOwed: null });

      expect(findSeatsOwedBlock().exists()).toBe(false);
    });
  });

  describe('purchase button', () => {
    it('renders purchase button if purchase link and purchase text is passed', () => {
      createComponent();

      const purchaseButton = findPurchaseButton();

      expect(purchaseButton.exists()).toBe(true);
      expect(purchaseButton.attributes('href')).toBe(purchaseButtonLink);
      expect(purchaseButton.attributes('target')).toBe('_blank');
    });

    it('does not render purchase button if purchase link is not passed', () => {
      createComponent({ purchaseButtonLink: null });

      expect(findPurchaseButton().exists()).toBe(false);
    });
  });
});
