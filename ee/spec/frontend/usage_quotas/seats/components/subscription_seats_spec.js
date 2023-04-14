import {
  GlPagination,
  GlButton,
  GlTable,
  GlAvatarLink,
  GlAvatarLabeled,
  GlBadge,
  GlModal,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import StatisticsSeatsCard from 'ee/usage_quotas/components/statistics_seats_card.vue';
import SubscriptionUpgradeInfoCard from 'ee/usage_quotas/seats/components/subscription_upgrade_info_card.vue';
import SubscriptionSeats from 'ee/usage_quotas/seats/components/subscription_seats.vue';
import {
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
  SORT_OPTIONS,
} from 'ee/usage_quotas/seats/constants';

import { mockDataSeats, mockTableItems } from 'ee_jest/usage_quotas/seats/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SearchAndSortBar from 'ee/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';

Vue.use(Vuex);

const actionSpies = {
  fetchBillableMembersList: jest.fn(),
  fetchGitlabSubscription: jest.fn(),
  setBillableMemberToRemove: jest.fn(),
  setSearchQuery: jest.fn(),
  changeMembershipState: jest.fn(),
};

const providedFields = {
  namespaceName: 'Test Group Name',
  namespaceId: '1000',
  seatUsageExportPath: '/groups/test_group/-/seat_usage.csv',
  maxFreeNamespaceSeats: 5,
  explorePlansPath: '/groups/test_group/-/billings',
  hasNoSubscription: false,
  hasLimitedFreePlan: false,
  hasReachedFreePlanLimit: false,
  notificationFreeUserCapEnabled: false,
  activeTrial: false,
};

const fakeStore = ({ initialState, initialGetters }) =>
  new Vuex.Store({
    actions: actionSpies,
    getters: {
      tableItems: () => mockTableItems,
      isLoading: () => false,
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

  const createComponent = ({
    initialState = {},
    mountFn = shallowMount,
    initialGetters = {},
    provide = {},
  } = {}) => {
    return extendedWrapper(
      mountFn(SubscriptionSeats, {
        store: fakeStore({ initialState, initialGetters }),
        provide,
      }),
    );
  };

  const findTable = () => wrapper.findComponent(GlTable);

  const findExportButton = () => wrapper.findByTestId('export-button');

  const findSearchAndSortBar = () => wrapper.findComponent(SearchAndSortBar);
  const findPagination = () => wrapper.findComponent(GlPagination);

  const findAllRemoveUserItems = () => wrapper.findAllByTestId('remove-user');
  const findErrorModal = () => wrapper.findComponent(GlModal);
  const findStatisticsCard = () => wrapper.findComponent(StatisticsCard);
  const findStatisticsSeatsCard = () => wrapper.findComponent(StatisticsSeatsCard);
  const findSubscriptionUpgradeCard = () => wrapper.findComponent(SubscriptionUpgradeInfoCard);
  const findSkeletonLoaderCards = () => wrapper.findByTestId('skeleton-loader-cards');

  const serializeUser = (rowWrapper) => {
    const avatarLink = rowWrapper.findComponent(GlAvatarLink);
    const avatarLabeled = rowWrapper.findComponent(GlAvatarLabeled);

    return {
      avatarLink: {
        href: avatarLink.attributes('href'),
        alt: avatarLink.attributes('alt'),
      },
      avatarLabeled: {
        src: avatarLabeled.attributes('src'),
        size: avatarLabeled.attributes('size'),
        text: avatarLabeled.text(),
      },
    };
  };

  const serializeTableRow = (rowWrapper) => {
    const emailWrapper = rowWrapper.find('[data-testid="email"]');

    return {
      user: serializeUser(rowWrapper),
      email: emailWrapper.text(),
      tooltip: emailWrapper.find('span').attributes('title'),
      removeUserButtonExists: rowWrapper.findComponent(GlButton).exists(),
      lastActivityOn: rowWrapper.find('[data-testid="last_activity_on"]').text(),
      lastLoginAt: rowWrapper.find('[data-testid="last_login_at"]').text(),
    };
  };

  const findSerializedTable = (tableWrapper) => {
    return tableWrapper.findAll('tbody tr').wrappers.map(serializeTableRow);
  };

  describe('actions', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('correct actions are called on create', () => {
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalled();
    });
  });

  describe('renders', () => {
    beforeEach(() => {
      wrapper = createComponent({
        mountFn: mount,
        initialGetters: {
          tableItems: () => mockTableItems,
        },
      });
    });

    describe('export button', () => {
      it('has the correct href', () => {
        expect(findExportButton().attributes().href).toBe(providedFields.seatUsageExportPath);
      });
    });

    describe('table content', () => {
      it('renders the correct data', () => {
        const serializedTable = findSerializedTable(findTable());

        expect(serializedTable).toMatchSnapshot();
      });
    });

    it('pagination is rendered and passed correct values', () => {
      const pagination = findPagination();

      expect(pagination.props()).toMatchObject({
        perPage: 5,
        totalItems: 300,
      });
    });

    describe('with error modal', () => {
      it('does not render the model if the user is not removable', async () => {
        await findAllRemoveUserItems().at(0).trigger('click');

        expect(findErrorModal().html()).toBe('');
      });

      it('renders the error modal if the user is removable', async () => {
        await findAllRemoveUserItems().at(2).trigger('click');

        expect(findErrorModal().text()).toContain(CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT);
      });
    });

    describe('members avatar', () => {
      it('shows the correct avatarLinks length', () => {
        const avatarLinks = findTable().findAllComponents(GlAvatarLink);
        expect(avatarLinks.length).toBe(6);
      });

      it.each(['group_invite', 'project_invite'])(
        'shows the correct badge for membership_type %s',
        (membershipType) => {
          const avatarLinks = findTable().findAllComponents(GlAvatarLink);
          const badgeText = (
            membershipType.charAt(0).toUpperCase() + membershipType.slice(1)
          ).replace('_', ' ');

          avatarLinks.wrappers.forEach((avatarLinkWrapper) => {
            const currentMember = mockTableItems.find(
              (item) => item.user.name === avatarLinkWrapper.attributes().alt,
            );

            if (membershipType === currentMember.user.membership_type) {
              expect(avatarLinkWrapper.findComponent(GlBadge).text()).toBe(badgeText);
            }
          });
        },
      );
    });

    describe('members details', () => {
      it.each`
        membershipType      | shouldShowDetails
        ${'project_invite'} | ${false}
        ${'group_invite'}   | ${false}
        ${'project_member'} | ${true}
        ${'group_member'}   | ${true}
      `(
        'when membershipType is $membershipType, shouldShowDetails should be $shouldShowDetails',
        ({ membershipType, shouldShowDetails }) => {
          mockTableItems.forEach((item) => {
            const detailsExpandButtons = findTable().find(
              `[data-testid="toggle-seat-usage-details-${item.user.id}"]`,
            );

            if (membershipType === item.user.membership_type) {
              expect(detailsExpandButtons.exists()).toBe(shouldShowDetails);
            }
          });
        },
      );
    });
  });

  describe('statistics cards', () => {
    const defaultInitialState = {
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
          const statisticsCard = findStatisticsCard();

          expect(statisticsCard.exists()).toBe(true);
          expect(statisticsCard.props()).toMatchObject({
            ...defaultProps,
            description: 'Seats in use / Seats in subscription',
            percentage: 67,
            totalValue: '3',
            usageValue: '2',
            helpTooltip: null,
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

        describe('when notification free user cap is enabled', () => {
          beforeEach(() => {
            wrapper = createComponent({
              initialState: {
                ...defaultInitialState,
                hasNoSubscription: true,
                hasLimitedFreePlan: false,
                notificationFreeUserCapEnabled: true,
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

    describe('for free namespace with free user cap notification enabled', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialState: {
            hasNoSubscription: true,
            hasLimitedFreePlan: false,
            notificationFreeUserCapEnabled: true,
          },
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
    describe('When nothing is loading', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('displays the table in a non-busy state', () => {
        expect(findTable().attributes('busy')).toBe(undefined);
      });
    });

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

      it('displays table in busy state', () => {
        expect(findTable().attributes('busy')).toBe('true');
      });
    });
  });

  describe('search box', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('input event triggers the setSearchQuery action', () => {
      const SEARCH_STRING = 'search string';

      findSearchAndSortBar().vm.$emit('onFilter', SEARCH_STRING);

      expect(actionSpies.setSearchQuery).toHaveBeenCalledTimes(1);
      expect(actionSpies.setSearchQuery).toHaveBeenCalledWith(expect.any(Object), SEARCH_STRING);
    });

    it('contains the correct sort options', () => {
      expect(findSearchAndSortBar().props('sortOptions')).toMatchObject(SORT_OPTIONS);
    });
  });

  describe('pending members alert', () => {
    it.each`
      pendingMembersPagePath | pendingMembersCount | hasLimitedFreePlan | notificationFreeUserCapEnabled | shouldBeRendered
      ${undefined}           | ${undefined}        | ${false}           | ${false}                       | ${false}
      ${undefined}           | ${0}                | ${false}           | ${false}                       | ${false}
      ${'fake-path'}         | ${0}                | ${false}           | ${false}                       | ${false}
      ${'fake-path'}         | ${3}                | ${true}            | ${false}                       | ${false}
      ${'fake-path'}         | ${3}                | ${false}           | ${true}                        | ${false}
      ${'fake-path'}         | ${3}                | ${false}           | ${false}                       | ${true}
    `(
      'rendering alert is $shouldBeRendered when pendingMembersPagePath=$pendingMembersPagePath and pendingMembersCount=$pendingMembersCount and hasLimitedFreePlan=$hasLimitedFreePlan and notificationFreeUserCapEnabled=$notificationFreeUserCapEnabled',
      ({
        pendingMembersPagePath,
        pendingMembersCount,
        shouldBeRendered,
        hasLimitedFreePlan,
        notificationFreeUserCapEnabled,
      }) => {
        wrapper = createComponent({
          initialState: {
            pendingMembersCount,
            pendingMembersPagePath,
            hasLimitedFreePlan,
            notificationFreeUserCapEnabled,
          },
        });

        expect(wrapper.find('[data-testid="pending-members-alert"]').exists()).toBe(
          shouldBeRendered,
        );
      },
    );
  });
});
