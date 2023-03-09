import { GlSprintf, GlIcon } from '@gitlab/ui';
import SummaryDetails from 'ee/subscriptions/buy_addons_shared/components/order_summary/summary_details.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';

describe('SummaryDetails', () => {
  useFakeDate(2021, 0, 16);

  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMountExtended(SummaryDetails, {
      propsData: {
        vat: 8,
        totalExVat: 10,
        selectedPlanText: 'Test',
        selectedPlanPrice: 10,
        totalAmount: 10,
        quantity: 1,
        ...props,
      },
      stubs: {
        GlSprintf,
        GlIcon,
      },
    });
  };

  const findQuantity = () => wrapper.findByTestId('quantity');
  const findSubscriptionPeriod = () => wrapper.findByTestId('subscription-period');
  const findTotalAmount = () => wrapper.findByTestId('total-amount');
  const findTotalExVat = () => wrapper.findByTestId('total-ex-vat');
  const findVat = () => wrapper.findByTestId('vat');
  const findVatHelpLink = () => wrapper.findByTestId('vat-help-link');
  const findVatInfoLine = () => wrapper.findByTestId('vat-info-line');
  const findToolip = () => wrapper.findComponent(GlIcon);

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the plan name', () => {
      expect(wrapper.findByTestId('selected-plan').text()).toMatchInterpolatedText('Test (x1)');
    });

    it('displays the total amount', () => {
      expect(findTotalAmount().text()).toBe('$10');
    });

    it('displays a help link', () => {
      expect(findVatHelpLink().attributes('href')).toBe(
        'https://about.gitlab.com/handbook/tax/#indirect-taxes-management',
      );
    });

    it('displays an info text', () => {
      expect(findVatInfoLine().text()).toMatchInterpolatedText(
        'Tax (may be charged upon purchase)',
      );
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
      wrapper = createComponent({ quantity: -1 });
    });

    it('does not render quantity', () => {
      expect(wrapper.findByTestId('quantity').exists()).toBe(false);
    });
  });

  describe('when subscription has expiration', () => {
    beforeEach(() => {
      wrapper = createComponent({ hasExpiration: true });
    });

    it('renders subscription period', () => {
      expect(findSubscriptionPeriod().isVisible()).toBe(true);
      expect(findSubscriptionPeriod().text()).toBe('Jan 16, 2021 - Jan 16, 2022');
    });

    it('hides a tooltip', () => {
      expect(findToolip().exists()).toBe(false);
    });
  });

  describe('when subscription has expiration and the end date provided', () => {
    beforeEach(() => {
      wrapper = createComponent({ subscriptionEndDate: '2021-02-06', hasExpiration: true });
    });

    it('renders subscription period', () => {
      expect(findSubscriptionPeriod().isVisible()).toBe(true);
      expect(findSubscriptionPeriod().text()).toBe('Jan 16, 2021 - Feb 6, 2021');
    });

    it('shows a tooltip', () => {
      expect(findToolip().isVisible()).toBe(true);
    });
  });

  describe('when subscription does not have expiration', () => {
    beforeEach(() => {
      wrapper = createComponent({ subscriptionEndDate: '' });
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

    it('displays a help link', () => {
      expect(findVatHelpLink().attributes('href')).toBe(
        'https://about.gitlab.com/handbook/tax/#indirect-taxes-management',
      );
    });

    it('displays an info text', () => {
      expect(findVatInfoLine().text()).toMatchInterpolatedText(
        'Tax (may be charged upon purchase)',
      );
    });
  });

  describe('when tax rate is not applied', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays the vat amount with a stopgap', () => {
      expect(findVat().text()).toBe('–');
    });
  });
});
