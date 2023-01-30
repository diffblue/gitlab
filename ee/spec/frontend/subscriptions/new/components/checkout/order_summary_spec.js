import Vue from 'vue';
import Vuex from 'vuex';
import { triggerEvent, mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Component from 'ee/subscriptions/new/components/order_summary.vue';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PromoCodeInput from 'ee/subscriptions/new/components/promo_code_input.vue';

describe('Order Summary', () => {
  Vue.use(Vuex);

  let wrapper;
  let trackingSpy;

  const availablePlans = [
    { id: 'firstPlanId', code: 'bronze', price_per_year: 48, name: 'bronze plan' },
    {
      id: 'secondPlanId',
      code: 'silver',
      price_per_year: 228,
      name: 'silver plan',
      eligible_to_use_promo_code: true,
    },
    {
      id: 'thirdPlanId',
      code: 'gold',
      price_per_year: 1188,
      name: 'gold plan',
      eligible_to_use_promo_code: false,
    },
  ];

  const initialData = {
    availablePlans: JSON.stringify(availablePlans),
    planId: 'thirdPlanId',
    namespaceId: null,
    fullName: 'Full Name',
  };

  const findTaxInfoLine = () => wrapper.findByTestId('tax-info-line');
  const findTaxHelpLink = () => wrapper.findByTestId('tax-help-link');
  const findPromoCodeInput = () => wrapper.findComponent(PromoCodeInput);

  const store = createStore(initialData);
  const createComponent = (opts = {}) => {
    wrapper = mountExtended(Component, {
      store,
      ...opts,
    });
  };

  beforeEach(() => {
    createComponent();
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
    wrapper.destroy();
  });

  describe('Changing the company name', () => {
    describe('When purchasing for a single user', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, false);
      });

      it('displays the title with the passed name', () => {
        expect(wrapper.find('h4').text()).toContain("Full Name's GitLab subscription");
      });
    });

    describe('When purchasing for a company or group', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
      });

      describe('Without a group name provided', () => {
        it('displays the title with the default name', () => {
          expect(wrapper.find('h4').text()).toContain("Your organization's GitLab subscription");
        });
      });

      describe('With a group name provided', () => {
        beforeEach(() => {
          store.commit(types.UPDATE_ORGANIZATION_NAME, 'My group');
        });

        it('displays the title with the group name', () => {
          expect(wrapper.find('h4').text()).toContain("My group's GitLab subscription");
        });
      });
    });
  });

  describe('Changing the plan', () => {
    describe('the selected plan', () => {
      it('displays the chosen plan', () => {
        expect(wrapper.find('.js-selected-plan').text()).toContain('Gold plan');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(wrapper.find('.js-per-user').text()).toContain('$1,188 per user per year');
      });
    });

    describe('with the default plan', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
        store.commit(types.UPDATE_NUMBER_OF_USERS, 1);
      });

      it('displays the chosen plan', () => {
        expect(wrapper.find('.js-selected-plan').text()).toContain('Bronze plan');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(wrapper.find('.js-per-user').text()).toContain('$48 per user per year');
      });

      it('displays the correct formatted total amount', () => {
        expect(wrapper.find('.js-total-amount').text()).toContain('$48');
      });
    });
  });

  describe('Changing the number of users', () => {
    beforeEach(() => {
      store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');
      store.commit(types.UPDATE_NUMBER_OF_USERS, 1);
    });

    describe('with the default of 1 selected user', () => {
      it('displays the correct number of users', () => {
        expect(wrapper.find('.js-number-of-users').text()).toContain('(x1)');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(wrapper.find('.js-per-user').text()).toContain('$1,188 per user per year');
      });

      it('displays the correct multiplied formatted amount of the chosen plan', () => {
        expect(wrapper.find('.js-amount').text()).toContain('$1,188');
      });

      it('displays the correct formatted total amount', () => {
        expect(wrapper.find('.js-total-amount').text()).toContain('$1,188');
      });
    });

    describe('with 3 selected users', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');
        store.commit(types.UPDATE_NUMBER_OF_USERS, 3);
      });

      it('displays the correct number of users', () => {
        expect(wrapper.find('.js-number-of-users').text()).toContain('(x3)');
      });

      it('displays the correct formatted amount price per user', () => {
        expect(wrapper.find('.js-per-user').text()).toContain('$1,188 per user per year');
      });

      it('displays the correct multiplied formatted amount of the chosen plan', () => {
        expect(wrapper.find('.js-amount').text()).toContain('$3,564');
      });

      it('displays the correct formatted total amount', () => {
        expect(wrapper.find('.js-total-amount').text()).toContain('$3,564');
      });
    });

    describe('with no selected users', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');
        store.commit(types.UPDATE_NUMBER_OF_USERS, 0);
      });

      it('should not display the number of users', () => {
        expect(wrapper.find('.js-number-of-users').exists()).toBe(false);
      });

      it('displays the correct formatted amount price per user', () => {
        expect(wrapper.find('.js-per-user').text()).toContain('$1,188 per user per year');
      });

      it('should not display the amount', () => {
        expect(wrapper.find('.js-amount').text()).toContain('-');
      });

      it('displays the correct formatted total amount', () => {
        expect(wrapper.find('.js-total-amount').text()).toContain('-');
      });
    });

    describe('date range', () => {
      beforeEach(() => {
        store.state.startDate = new Date('2019-12-05');
      });

      it('shows the formatted date range from the start date to one year in the future', () => {
        expect(wrapper.find('.js-dates').text()).toContain('Dec 5, 2019 - Dec 5, 2020');
      });
    });

    describe('tax rate', () => {
      describe('tracking', () => {
        it('track click on tax_link', () => {
          trackingSpy = mockTracking(undefined, findTaxHelpLink().element, jest.spyOn);
          triggerEvent(findTaxHelpLink().element);

          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
            label: 'tax_link',
          });
        });
      });

      describe('with a tax rate of 0', () => {
        it('displays the total amount excluding vat', () => {
          expect(wrapper.find('.js-total-ex-vat').exists()).toBe(true);
        });

        it('displays the vat amount with a stopgap', () => {
          expect(wrapper.find('.js-vat').text()).toBe('–');
        });

        it('displays an info line', () => {
          expect(findTaxInfoLine().text()).toMatchInterpolatedText(
            'Tax (may be charged upon purchase)',
          );
        });

        it('contains a help link', () => {
          expect(findTaxHelpLink().attributes('href')).toBe(
            'https://about.gitlab.com/handbook/tax/#indirect-taxes-management',
          );
        });
      });

      describe('a tax rate of 8%', () => {
        beforeEach(() => {
          store.state.taxRate = 0.08;
        });

        it('displays the total amount excluding vat', () => {
          expect(wrapper.find('.js-total-ex-vat').text()).toContain('$1,188');
        });

        it('displays the vat amount', () => {
          expect(wrapper.find('.js-vat').text()).toContain('$95.04');
        });

        it('displays the total amount including the vat', () => {
          expect(wrapper.find('.js-total-amount').text()).toContain('$1,283.04');
        });

        it('displays an info line', () => {
          expect(findTaxInfoLine().text()).toMatchInterpolatedText(
            'Tax (may be charged upon purchase)',
          );
        });

        it('contains a help link', () => {
          expect(findTaxHelpLink().attributes('href')).toBe(
            'https://about.gitlab.com/handbook/tax/#indirect-taxes-management',
          );
        });
      });
    });
  });

  describe('promo code', () => {
    it('shows promo code input if eligible', async () => {
      await store.commit(types.UPDATE_SELECTED_PLAN, 'secondPlanId');

      expect(findPromoCodeInput().exists()).toBe(true);
    });

    it('doesnt show promo code input if not eligible', async () => {
      await store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');

      expect(findPromoCodeInput().exists()).toBe(false);

      await store.commit(types.UPDATE_SELECTED_PLAN, 'thirdPlanId');

      expect(findPromoCodeInput().exists()).toBe(false);
    });
  });
});
