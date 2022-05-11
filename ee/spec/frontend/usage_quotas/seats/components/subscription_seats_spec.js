import {
  GlAlert,
  GlPagination,
  GlButton,
  GlTable,
  GlAvatarLink,
  GlAvatarLabeled,
  GlBadge,
  GlModal,
  GlToggle,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import StatisticsSeatsCard from 'ee/usage_quotas/components/statistics_seats_card.vue';
import SubscriptionUpgradeInfoCard from 'ee/usage_quotas/seats/components/subscription_upgrade_info_card.vue';
import SubscriptionSeats from 'ee/usage_quotas/seats/components/subscription_seats.vue';
import { CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT } from 'ee/usage_quotas/seats/constants';
import { mockDataSeats, mockTableItems } from 'ee_jest/usage_quotas/seats/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import FilterSortContainerRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

Vue.use(Vuex);

const actionSpies = {
  fetchBillableMembersList: jest.fn(),
  fetchGitlabSubscription: jest.fn(),
  resetBillableMembers: jest.fn(),
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
};

const fakeStore = ({ initialState, initialGetters }) =>
  new Vuex.Store({
    actions: actionSpies,
    getters: {
      tableItems: () => mockTableItems,
      ...initialGetters,
    },
    state: {
      isLoading: false,
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

  const findSearchBox = () => wrapper.findComponent(FilterSortContainerRoot);
  const findPagination = () => wrapper.findComponent(GlPagination);

  const findAllRemoveUserItems = () => wrapper.findAllByTestId('remove-user');
  const findErrorModal = () => wrapper.findComponent(GlModal);
  const findStatisticsCard = () => wrapper.findComponent(StatisticsCard);
  const findStatisticsSeatsCard = () => wrapper.findComponent(StatisticsSeatsCard);
  const findSubscriptionUpgradeCard = () => wrapper.findComponent(SubscriptionUpgradeInfoCard);

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

  const serializeToggle = (rowWrapper) => {
    const toggle = rowWrapper.findComponent(GlToggle);

    if (!toggle.exists()) {
      return null;
    }

    return {
      disabled: toggle.props().disabled,
      title: toggle.attributes('title'),
      value: toggle.props().value,
    };
  };

  const serializeTableRow = (rowWrapper) => {
    const emailWrapper = rowWrapper.find('[data-testid="email"]');

    return {
      user: serializeUser(rowWrapper),
      email: emailWrapper.text(),
      tooltip: emailWrapper.find('span').attributes('title'),
      toggle: serializeToggle(rowWrapper),
      removeUserButtonExists: rowWrapper.findComponent(GlButton).exists(),
    };
  };

  const findSerializedTable = (tableWrapper) => {
    return tableWrapper.findAll('tbody tr').wrappers.map(serializeTableRow);
  };

  describe('actions', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
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

    afterEach(() => {
      wrapper.destroy();
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

      describe('membership toggles', () => {
        it.each`
          hasNoSubscription | hasLimitedFreePlan | shouldBeRendered
          ${false}          | ${false}           | ${false}
          ${true}           | ${false}           | ${false}
          ${true}           | ${true}            | ${true}
        `(
          'rendering toggles $shouldBeRendered when hasLimitedFreePlan=$hasLimitedFreePlan and hasNoSubscription=$hasNoSubscription',
          ({ hasNoSubscription, hasLimitedFreePlan, shouldBeRendered }) => {
            wrapper = createComponent({
              mountFn: mount,
              initialGetters: {
                tableItems: () => mockTableItems,
              },
              initialState: {
                hasNoSubscription,
                hasLimitedFreePlan,
              },
            });

            const toggles = findTable().findAllComponents(GlToggle);
            expect(toggles.exists()).toBe(shouldBeRendered);
          },
        );

        describe('when limited free plan reached limit', () => {
          let serializedTable;

          beforeEach(() => {
            wrapper = createComponent({
              mountFn: mount,
              initialGetters: {
                tableItems: () => mockTableItems,
              },
              initialState: {
                hasNoSubscription: true,
                hasLimitedFreePlan: true,
                hasReachedFreePlanLimit: true,
              },
            });

            serializedTable = findSerializedTable(findTable());
          });

          it('sets toggle props correctly for active users', () => {
            serializedTable.forEach((serializedRow) => {
              const currentMember = mockTableItems.find((item) => {
                return item.user.name === serializedRow.user.avatarLink.alt;
              });

              if (currentMember.user.membership_state === 'active') {
                expect(serializedRow.toggle.disabled).toBe(false);
                expect(serializedRow.toggle.title).toBe('');
                expect(serializedRow.toggle.value).toBe(true);
              }
            });
          });

          it('sets toggle props correctly for awaiting users', () => {
            serializedTable.forEach((serializedRow) => {
              const currentMember = mockTableItems.find((item) => {
                return item.user.name === serializedRow.user.avatarLink.alt;
              });

              if (currentMember.user.membership_state === 'awaiting') {
                expect(serializedRow.toggle.disabled).toBe(true);
                expect(serializedRow.toggle.title).toBe(
                  'To make this member active, you must first remove an existing active member, or toggle them to over limit.',
                );
                expect(serializedRow.toggle.value).toBe(false);
              }
            });
          });

          it('disables the toggles when isLoading=true', () => {
            wrapper = createComponent({
              mountFn: mount,
              initialGetters: {
                tableItems: () => mockTableItems,
              },
              initialState: {
                isLoading: true,
                hasNoSubscription: true,
                hasLimitedFreePlan: true,
                hasReachedFreePlanLimit: true,
              },
            });

            serializedTable = findSerializedTable(findTable());

            serializedTable.forEach((serializedRow) => {
              expect(serializedRow.toggle.disabled).toBe(true);
            });
          });

          it('calls the changeMembershipState action when clicking the toggle', () => {
            const toggles = findTable().findComponent(GlToggle);

            toggles.vm.$emit('change', false);

            expect(actionSpies.changeMembershipState).toHaveBeenCalledWith(
              expect.any(Object),
              mockTableItems[0].user,
            );
          });
        });
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
        expect(avatarLinks.length).toBe(4);
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
          const seatCells = findTable().findAll('[data-testid*="seat-cell-"]');

          seatCells.wrappers.forEach((seatCellWrapper) => {
            const currentMember = mockTableItems.find(
              (item) => seatCellWrapper.attributes('data-testid') === `seat-cell-${item.user.id}`,
            );

            if (membershipType === currentMember.user.membership_type) {
              expect(
                seatCellWrapper.find('[data-testid="toggle-seat-usage-details"]').exists(),
              ).toBe(shouldShowDetails);
            }
          });
        },
      );
    });
  });

  describe('statistics cards', () => {
    const defaultInitialState = {
      seatsInSubscription: 3,
      total: 10,
      seatsInUse: 2,
      maxSeatsUsed: 3,
      seatsOwed: 1,
    };

    const defaultProps = {
      helpLink: '/help/subscription/gitlab_com/index#how-seat-usage-is-determined',
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
          expect(statisticsCard.props()).toEqual(
            expect.objectContaining({
              ...defaultProps,
              description: 'Seats in use / Seats in subscription',
              percentage: 67,
              totalValue: '3',
              usageValue: '2',
            }),
          );
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
              },
            });
          });

          it('renders <statistics-card> with the necessary props', () => {
            const statisticsCard = findStatisticsCard();

            expect(statisticsCard.exists()).toBe(true);
            expect(statisticsCard.props()).toEqual(
              expect.objectContaining({
                ...defaultProps,
                description: 'Seats in use / Seats in subscription',
                percentage: 0,
                totalValue: '-',
                usageValue: '10',
              }),
            );
          });
        });

        describe('when on limited free plan', () => {
          beforeEach(() => {
            wrapper = createComponent({
              initialState: {
                ...defaultInitialState,
                hasNoSubscription: true,
                hasLimitedFreePlan: true,
              },
            });
          });

          it('renders <statistics-card> with the necessary props', () => {
            const statisticsCard = findStatisticsCard();

            expect(statisticsCard.exists()).toBe(true);
            expect(statisticsCard.props()).toEqual(
              expect.objectContaining({
                ...defaultProps,
                description: 'Seats in use / Seats available',
                percentage: 40,
                totalValue: '5',
                usageValue: '2',
              }),
            );
          });
        });
      });
    });

    it('renders <statistics-seats-card> with the necessary props', () => {
      const statisticsSeatsCard = findStatisticsSeatsCard();

      expect(findSubscriptionUpgradeCard().exists()).toBe(false);
      expect(statisticsSeatsCard.exists()).toBe(true);
      expect(statisticsSeatsCard.props()).toEqual(
        expect.objectContaining({
          seatsOwed: 1,
          seatsUsed: 3,
        }),
      );
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
        expect(upgradeInfoCard.props()).toEqual(
          expect.objectContaining({
            maxNamespaceSeats: providedFields.maxFreeNamespaceSeats,
            explorePlansPath: providedFields.explorePlansPath,
          }),
        );
      });
    });
  });

  describe('is loading', () => {
    beforeEach(() => {
      wrapper = createComponent({ initialState: { isLoading: true } });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('displays table in loading state', () => {
      expect(findTable().attributes('busy')).toBe('true');
    });
  });

  describe('search box', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('input event triggers the setSearchQuery action', async () => {
      const SEARCH_STRING = 'search string';

      // fetchBillableMembersList is called once on created()
      expect(actionSpies.fetchBillableMembersList).toHaveBeenCalledTimes(1);

      await findSearchBox().vm.$emit('onFilter', [
        { type: 'filtered-search-term', value: { data: SEARCH_STRING } },
      ]);

      expect(actionSpies.setSearchQuery).toHaveBeenCalledWith(expect.any(Object), SEARCH_STRING);
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

        expect(wrapper.findComponent(GlAlert).exists()).toBe(shouldBeRendered);
      },
    );
  });
});
