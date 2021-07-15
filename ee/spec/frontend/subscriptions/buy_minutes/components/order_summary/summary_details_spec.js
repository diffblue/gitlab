import { shallowMount } from '@vue/test-utils';
import SummaryDetails from 'ee/subscriptions/buy_minutes/components/order_summary/summary_details.vue';

describe('SummaryDetails', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMount(SummaryDetails, {
      propsData: {
        vat: 8,
        totalExVat: 10,
        selectedPlanText: 'Test',
        selectedPlanPrice: 10,
        totalAmount: 10,
        quantity: 1,
        ...props,
      },
    });
  };

  const findQuantity = () => wrapper.find('[data-testid="quantity"]');
  const findSubscriptionPeriod = () => wrapper.find('[data-testid="subscription-period"]');
  const findTotalExVat = () => wrapper.find('[data-testid="total-ex-vat"]');
  const findVat = () => wrapper.find('[data-testid="vat"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the plan name', () => {
      expect(wrapper.find('[data-testid="selected-plan"]').text()).toMatchInterpolatedText(
        'Test plan (x1)',
      );
    });

    it('renders the price per unit', () => {
      expect(wrapper.find('[data-testid="price-per-unit"]').text()).toBe('$10 per pack per year');
    });
  });

  describe('when quantity is greater then zero', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders quantity', () => {
      expect(findQuantity().isVisible()).toBe(true);
      expect(findQuantity().text()).toBe('(x1)');
    });
  });

  describe('when quantity is less or equal to zero', () => {
    beforeEach(() => {
      wrapper = createComponent({ quantity: 0 });
    });

    it('does not render quantity', () => {
      expect(wrapper.find('[data-testid="quantity"]').exists()).toBe(false);
    });
  });

  describe('when subscription has expiration', () => {
    beforeEach(() => {
      wrapper = createComponent({ purchaseHasExpiration: true });
    });

    it('renders subscription period', () => {
      expect(findSubscriptionPeriod().isVisible()).toBe(true);
      expect(findSubscriptionPeriod().text()).toBe('Jul 6, 2020 - Jul 6, 2021');
    });
  });

  describe('when subscription does not have expiration', () => {
    beforeEach(() => {
      wrapper = createComponent({ purchaseHasExpiration: false });
    });

    it('does not render subscription period', () => {
      expect(findSubscriptionPeriod().exists()).toBe(false);
    });
  });

  describe('when tax rate is applied', () => {
    beforeEach(() => {
      wrapper = createComponent({ taxRate: 8 });
    });

    it('renders tax fields', () => {
      expect(findTotalExVat().isVisible()).toBe(true);
      expect(findTotalExVat().text()).toBe('$10');

      expect(findVat().isVisible()).toBe(true);
      expect(findVat().text()).toBe('$8');
    });
  });

  describe('when tax rate is not applied', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not render tax fields', () => {
      expect(findTotalExVat().exists()).toBe(false);
      expect(findVat().exists()).toBe(false);
    });
  });
});
