import Vue from 'vue';
import Vuex from 'vuex';
import { PLAN_CODE_FREE, addSeatsText, seatsInUseLink } from 'ee/usage_quotas/seats/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/usage_quotas/seats/store';
import initState from 'ee/usage_quotas/seats/store/state';
import SubscriptionUsageStatisticsCard from 'ee/usage_quotas/seats/components/subscription_usage_statistics_card.vue';
import UsageStatistics from 'ee/usage_quotas/components/usage_statistics.vue';

Vue.use(Vuex);

describe('SubscriptionUsageStatisticsCard', () => {
  let wrapper;

  const addSeatsHref = 'add/seats/href';
  const maxFreeNamespaceSeats = 5;
  const percentage = 50;
  const usageValue = '10';
  const totalValue = '100';

  const findAddSeatsButton = () => wrapper.findByTestId('add-seats');
  const findSeatsInUseLink = () => wrapper.findByTestId('seats-used-link');
  const findSeatsOwedSection = () => wrapper.findByTestId('seats-owed');
  const findSeatsUsedSection = () => wrapper.findByTestId('seats-used');
  const findSeatsUsedText = () => wrapper.findByTestId('seats-used-text');
  const findSubscriptionStartDate = () => wrapper.findByTestId('subscription-start-date');
  const findSubscriptionEndDate = () => wrapper.findByTestId('subscription-end-date');
  const findUsageStatistics = () => wrapper.findComponent(UsageStatistics);

  const createWrapper = ({ props = {}, storeOptions = {} } = {}) => {
    const store = createStore(initState());
    store.state = {
      ...store.state,
      activeTrial: null,
      addSeatsHref,
      hasLimitedFreePlan: null,
      maxFreeNamespaceSeats,
      maxSeatsUsed: null,
      planCode: null,
      seatsOwed: null,
      subscriptionEndDate: '2024-03-16',
      subscriptionStartDate: '2023-03-16',
      ...storeOptions,
    };

    wrapper = shallowMountExtended(SubscriptionUsageStatisticsCard, {
      store,
      propsData: { percentage, usageValue, totalValue, ...props },
      stubs: {
        UsageStatistics: {
          template: `
            <div>
                <slot name="actions"></slot>
                <slot name="description"></slot>
                <slot name="additional-info"></slot>
            </div>
            `,
        },
      },
    });
  };

  describe('on mount', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the component', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('renders the usage statistics component with correct props', () => {
      expect(findUsageStatistics().attributes()).toEqual({
        percentage: `${percentage}`,
        'total-value': totalValue,
        'usage-value': usageValue,
      });
    });
  });

  describe('with the description section', () => {
    it('does not render the seats in use description text', () => {
      createWrapper();

      expect(findSeatsUsedText().exists()).toBe(false);
    });

    describe('when the plan code is provided', () => {
      beforeEach(() => {
        createWrapper({ storeOptions: { planCode: 'ultimate' } });
      });

      it('renders the seats in use description text', () => {
        expect(findSeatsUsedText().text()).toContain('Ultimate SaaS Plan seats used');
      });

      it('provides the correct href', () => {
        expect(findSeatsInUseLink().attributes('href')).toBe(seatsInUseLink);
      });

      it('provides the correct tooltip title', () => {
        expect(findSeatsInUseLink().attributes('title')).toBeUndefined();
      });

      describe('with an active trial', () => {
        it('provides the correct tooltip title', () => {
          createWrapper({
            storeOptions: {
              activeTrial: true,
              hasLimitedFreePlan: true,
              planCode: 'ultimate',
            },
          });

          expect(findSeatsInUseLink().attributes('title')).toBe(
            `Free tier and trial groups can invite a maximum of 20 members per day.`,
          );
        });
      });
    });

    describe('when has a limited free plan', () => {
      describe('with no active trial', () => {
        it('provides the correct tooltip title', () => {
          createWrapper({ storeOptions: { hasLimitedFreePlan: true, planCode: PLAN_CODE_FREE } });

          expect(findSeatsInUseLink().attributes('title')).toMatchInterpolatedText(
            `Free groups are limited to ${maxFreeNamespaceSeats} seats.`,
          );
        });
      });
    });
  });

  describe('with the `Add Seats` button', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the correct label', () => {
      expect(findAddSeatsButton().text()).toBe(addSeatsText);
    });

    it('renders the correct href', () => {
      expect(findAddSeatsButton().attributes('href')).toBe(addSeatsHref);
    });

    describe('with no href for add seats', () => {
      it('does not render the `Add Seats`', () => {
        createWrapper({ storeOptions: { addSeatsHref: null } });

        expect(findAddSeatsButton().exists()).toBe(false);
      });
    });
  });

  describe('with the seats used block', () => {
    beforeEach(() => {
      createWrapper({ storeOptions: { maxSeatsUsed: 5, seatsOwed: 10 } });
    });

    it('renders the seats used text', () => {
      expect(findSeatsUsedSection().text()).toBe('5 Max seats used');
    });

    it('renders the subscription start date', () => {
      expect(findSubscriptionStartDate().text()).toBe('March 16, 2023');
    });

    it('renders the seats owed text', () => {
      expect(findSeatsOwedSection().text()).toBe('10 Seats owed');
    });

    it('renders the subscription end date', () => {
      expect(findSubscriptionEndDate().text()).toBe('March 16, 2024');
    });
  });
});
