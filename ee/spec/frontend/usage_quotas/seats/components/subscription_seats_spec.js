import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import CodeSuggestionsUsageStatisticsCard from 'ee/usage_quotas/seats/components/code_suggestions_usage_statistics_card.vue';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import StatisticsSeatsCard from 'ee/usage_quotas/seats/components/statistics_seats_card.vue';
import SubscriptionUpgradeInfoCard from 'ee/usage_quotas/seats/components/subscription_upgrade_info_card.vue';
import SubscriptionUsageStatisticsCard from 'ee/usage_quotas/seats/components/subscription_usage_statistics_card.vue';
import SubscriptionSeats from 'ee/usage_quotas/seats/components/subscription_seats.vue';
import SubscriptionUserList from 'ee/usage_quotas/seats/components/subscription_user_list.vue';
import { mockDataSeats, mockTableItems } from 'ee_jest/usage_quotas/seats/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(Vuex);

const actionSpies = {
  fetchBillableMembersList: jest.fn(),
  fetchGitlabSubscription: jest.fn(),
};

const providedFields = {
  maxFreeNamespaceSeats: 5,
  explorePlansPath: '/groups/test_group/-/billings',
  hasNoSubscription: false,
  hasLimitedFreePlan: false,
  hasReachedFreePlanLimit: false,
  activeTrial: false,
};

const fakeStore = ({ initialState, initialGetters }) =>
  new Vuex.Store({
    actions: actionSpies,
    getters: {
      tableItems: () => mockTableItems,
      isLoading: () => false,
      hasFreePlan: () => false,
      ...initialGetters,
    },
    state: {
      hasError: false,
      namespaceId: 1,
      members: [...mockDataSeats.data],
      total: 300,
      page: 1,
      perPage: 5,
      sort: 'last_activity_on_desc',
      ...providedFields,
      ...initialState,
    },
  });

describe('Subscription Seats', () => {
  let wrapper;

  const createComponent = ({ initialState = {}, initialGetters = {}, provide = {} } = {}) => {
    return extendedWrapper(
      shallowMount(SubscriptionSeats, {
        store: fakeStore({ initialState, initialGetters }),
        provide: {
          glFeatures: {
            enableHamiltonInUsageQuotasUi: false,
          },
          ...provide,
        },
      }),
    );
  };

  const findCodeSuggestionsStatisticsCard = () =>
    wrapper.findComponent(CodeSuggestionsUsageStatisticsCard);
  const findStatisticsCard = () => wrapper.findComponent(StatisticsCard);
  const findStatisticsSeatsCard = () => wrapper.findComponent(StatisticsSeatsCard);
  const findSubscriptionUpgradeCard = () => wrapper.findComponent(SubscriptionUpgradeInfoCard);
  const findSkeletonLoaderCards = () => wrapper.findByTestId('skeleton-loader-cards');
  const findSubscriptionUsageStatisticsCard = () =>
    wrapper.findComponent(SubscriptionUsageStatisticsCard);
  const findSubscriptionUserList = () => wrapper.findComponent(SubscriptionUserList);

  describe('actions', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('correct actions are called on create', () => {
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalled();
    });
  });

  describe('statistics cards', () => {
    const defaultInitialState = {
      hasNoSubscription: false,
      seatsInSubscription: 3,
      total: 2,
      seatsInUse: 2,
      maxSeatsUsed: 3,
      seatsOwed: 1,
    };

    const defaultProps = {
      helpLink: '/help/subscriptions/gitlab_com/index#how-seat-usage-is-determined',
      totalUnit: null,
      usageUnit: null,
    };

    beforeEach(() => {
      wrapper = createComponent({
        initialState: defaultInitialState,
      });
    });

    it('calls the correct action on create', () => {
      expect(actionSpies.fetchGitlabSubscription).toHaveBeenCalled();
    });

    describe('renders <statistics-card>', () => {
      describe('when group has a subscription', () => {
        it('renders <statistics-card> with the necessary props', () => {
          expect(findStatisticsCard().props()).toMatchObject({
            ...defaultProps,
            description: 'Seats in use / Seats in subscription',
            percentage: 67,
            totalValue: '3',
            usageValue: '2',
            helpTooltip: null,
          });
        });

        describe('with `enable hamilton for usage quotas ui` enabled', () => {
          it(`renders <subscription-usage-statistics-card> with the necessary props`, () => {
            wrapper = createComponent({
              initialState: defaultInitialState,
              provide: { glFeatures: { enableHamiltonInUsageQuotasUi: true } },
            });

            expect(findSubscriptionUsageStatisticsCard().props()).toMatchObject({});
          });
        });
      });

      describe('when group has no subscription', () => {
        describe('when not on limited free plan', () => {
          beforeEach(() => {
            wrapper = createComponent({
              initialState: {
                ...defaultInitialState,
                hasNoSubscription: true,
                hasLimitedFreePlan: false,
                activeTrial: false,
              },
              initialGetters: {
                hasFreePlan: () => true,
              },
            });
          });

          it('renders <statistics-card> with the necessary props', () => {
            const statisticsCard = findStatisticsCard();

            expect(statisticsCard.exists()).toBe(true);
            expect(statisticsCard.props()).toMatchObject({
              ...defaultProps,
              description: 'Free seats used',
              percentage: 0,
              totalValue: 'Unlimited',
              usageValue: '2',
              helpTooltip: null,
            });
          });

          describe('when on trial', () => {
            beforeEach(() => {
              wrapper = createComponent({
                initialState: {
                  ...defaultInitialState,
                  hasNoSubscription: true,
                  hasLimitedFreePlan: false,
                  activeTrial: true,
                },
              });
            });

            it('renders <statistics-card> with the necessary props', () => {
              const statisticsCard = findStatisticsCard();

              expect(statisticsCard.exists()).toBe(true);
              expect(statisticsCard.props()).toMatchObject({
                ...defaultProps,
                description: 'Seats in use / Seats in subscription',
                percentage: 0,
                totalValue: 'Unlimited',
                usageValue: '2',
                helpTooltip: null,
              });
            });
          });
        });

        describe('when on limited free plan', () => {
          beforeEach(() => {
            wrapper = createComponent({
              initialState: {
                ...defaultInitialState,
                hasNoSubscription: true,
                hasLimitedFreePlan: true,
                activeTrial: false,
              },
            });
          });

          it('renders <statistics-card> with the necessary props', () => {
            const statisticsCard = findStatisticsCard();

            expect(statisticsCard.exists()).toBe(true);
            expect(statisticsCard.props()).toMatchObject({
              ...defaultProps,
              description: 'Seats in use / Seats available',
              percentage: 40,
              totalValue: '5',
              usageValue: '2',
              helpTooltip: 'Free groups are limited to 5 seats.',
            });
          });

          describe('when on trial', () => {
            beforeEach(() => {
              wrapper = createComponent({
                initialState: {
                  ...defaultInitialState,
                  hasNoSubscription: true,
                  hasLimitedFreePlan: true,
                  activeTrial: true,
                },
              });
            });

            it('renders <statistics-card> with the necessary props', () => {
              const statisticsCard = findStatisticsCard();

              expect(statisticsCard.exists()).toBe(true);
              expect(statisticsCard.props()).toMatchObject({
                ...defaultProps,
                description: 'Seats in use / Seats available',
                percentage: 0,
                totalValue: 'Unlimited',
                usageValue: '2',
                helpTooltip:
                  'Free tier and trial groups can invite a maximum of 20 members per day.',
              });
            });
          });
        });
      });
    });

    it('renders <statistics-seats-card> with the necessary props', () => {
      const statisticsSeatsCard = findStatisticsSeatsCard();

      expect(findSubscriptionUpgradeCard().exists()).toBe(false);
      expect(statisticsSeatsCard.exists()).toBe(true);
      expect(statisticsSeatsCard.props()).toMatchObject({
        seatsOwed: 1,
        seatsUsed: 3,
      });
    });

    it('renders <code-suggestions-usage-statistics-card>', () => {
      wrapper = createComponent({
        initialState: {
          ...defaultInitialState,
          hasNoSubscription: false,
        },
        provide: {
          glFeatures: {
            enableHamiltonInUsageQuotasUi: true,
          },
        },
      });

      expect(findStatisticsSeatsCard().exists()).toBe(false);
      expect(findCodeSuggestionsStatisticsCard().exists()).toBe(true);
    });

    describe('for free namespace with limit', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialState: { hasNoSubscription: true, hasLimitedFreePlan: true },
        });
      });

      it('renders <subscription-upgrade-info-card> with the necessary props', () => {
        const upgradeInfoCard = findSubscriptionUpgradeCard();

        expect(findStatisticsSeatsCard().exists()).toBe(false);
        expect(upgradeInfoCard.exists()).toBe(true);
        expect(upgradeInfoCard.props()).toMatchObject({
          maxNamespaceSeats: providedFields.maxFreeNamespaceSeats,
          explorePlansPath: providedFields.explorePlansPath,
          activeTrial: false,
        });
      });
    });
  });

  describe('Loading state', () => {
    describe.each([
      [true, false],
      [false, true],
    ])('Busy when isLoading=%s and hasError=%s', (isLoading, hasError) => {
      beforeEach(() => {
        wrapper = createComponent({
          initialGetters: { isLoading: () => isLoading },
          initialState: { hasError },
        });
      });

      it('displays loading skeletons instead of statistics cards', () => {
        expect(findSkeletonLoaderCards().exists()).toBe(true);
        expect(findStatisticsCard().exists()).toBe(false);
        expect(findStatisticsSeatsCard().exists()).toBe(false);
      });
    });
  });

  describe('pending members alert', () => {
    it.each`
      pendingMembersPagePath | pendingMembersCount | hasLimitedFreePlan | shouldBeRendered
      ${undefined}           | ${undefined}        | ${false}           | ${false}
      ${undefined}           | ${0}                | ${false}           | ${false}
      ${'fake-path'}         | ${0}                | ${false}           | ${false}
      ${'fake-path'}         | ${3}                | ${true}            | ${false}
      ${'fake-path'}         | ${3}                | ${false}           | ${true}
    `(
      'rendering alert is $shouldBeRendered when pendingMembersPagePath=$pendingMembersPagePath and pendingMembersCount=$pendingMembersCount and hasLimitedFreePlan=$hasLimitedFreePlan',
      ({ pendingMembersPagePath, pendingMembersCount, shouldBeRendered, hasLimitedFreePlan }) => {
        wrapper = createComponent({
          initialState: {
            pendingMembersCount,
            pendingMembersPagePath,
            hasLimitedFreePlan,
          },
        });

        expect(wrapper.find('[data-testid="pending-members-alert"]').exists()).toBe(
          shouldBeRendered,
        );
      },
    );
  });

  describe('subscription user list', () => {
    it('renders subscription users', () => {
      wrapper = createComponent();

      expect(findSubscriptionUserList().exists()).toBe(true);
    });
  });
});
