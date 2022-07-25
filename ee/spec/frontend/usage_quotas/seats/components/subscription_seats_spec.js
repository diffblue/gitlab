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
  GlSprintf,
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
  RENDER_SEATS_PAGE_TRACK_LABEL,
  RENDER_SEATS_ALERT_TRACK_LABEL,
  DISMISS_SEATS_ALERT_TRACK_LABEL,
  DISMISS_SEATS_ALERT_COOKIE_NAME,
} from 'ee/usage_quotas/seats/constants';

import { mockDataSeats, mockTableItems } from 'ee_jest/usage_quotas/seats/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import FilterSortContainerRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { getCookie, setCookie } from '~/lib/utils/common_utils';

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
  previewFreeUserCap: false,
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
        stubs: { GlAlert, GlSprintf },
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
  const findSeatsAlertBanner = () => wrapper.findByTestId('seats-alert-banner');

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
      label: toggle.props().label,
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
          hasNoSubscription | hasLimitedFreePlan | previewFreeUserCap | shouldBeRendered
          ${false}          | ${false}           | ${false}           | ${false}
          ${true}           | ${false}           | ${false}           | ${false}
          ${true}           | ${true}            | ${false}           | ${true}
          ${true}           | ${false}           | ${true}            | ${true}
        `(
          'rendering toggles $shouldBeRendered when hasLimitedFreePlan=$hasLimitedFreePlan and hasNoSubscription=$hasNoSubscription and previewFreeUserCap=$previewFreeUserCap',
          ({ hasNoSubscription, hasLimitedFreePlan, previewFreeUserCap, shouldBeRendered }) => {
            wrapper = createComponent({
              mountFn: mount,
              initialGetters: {
                tableItems: () => mockTableItems,
              },
              initialState: {
                hasNoSubscription,
                hasLimitedFreePlan,
                previewFreeUserCap,
              },
            });

            const toggles = findTable().findAllComponents(GlToggle);
            expect(toggles.exists()).toBe(shouldBeRendered);
          },
        );

        describe('when limited free plan reached limit', () => {
          let serializedTable;

          const forEachUser = (callback) => {
            serializedTable.forEach((serializedRow) => {
              const currentItem = mockTableItems.find(
                (item) => item.user.name === serializedRow.user.avatarLink.alt,
              );
              callback(currentItem.user, serializedRow);
            });
          };

          beforeEach(() => {
            global.gon.current_user_id = mockTableItems[mockTableItems.length - 1].user.id;

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

          it('sets toggle label correctly', () => {
            forEachUser((_, serializedRow) => {
              expect(serializedRow.toggle.label).toBe('In a seat');
            });
          });

          it('sets toggle value correctly for active users', () => {
            forEachUser((user, serializedRow) => {
              if (user.membership_state === 'active') {
                expect(serializedRow.toggle.value).toBe(true);
              }
            });
          });

          it('sets toggle value correctly for awaiting users', () => {
            forEachUser((user, serializedRow) => {
              if (user.membership_state === 'awaiting') {
                expect(serializedRow.toggle.value).toBe(false);
              }
            });
          });

          it('sets toggle props correctly for last owners', () => {
            forEachUser((user, serializedRow) => {
              if (user.is_last_owner) {
                expect(serializedRow.toggle.disabled).toBe(true);
                expect(serializedRow.toggle.title).toBe(
                  'The last owner cannot be removed from a seat.',
                );
              }
            });
          });

          it('sets toggle props correctly for group or project invites', () => {
            forEachUser((user, serializedRow) => {
              if (
                user.membership_type === 'group_invite' ||
                user.membership_type === 'project_invite'
              ) {
                expect(serializedRow.toggle.disabled).toBe(true);
                expect(serializedRow.toggle.title).toBe(
                  "You can't change the seat status of a user who was invited via a group or project.",
                );
              }
            });
          });

          it('sets toggle props correctly for awaiting group or project members', () => {
            forEachUser((user, serializedRow) => {
              if (user.membership_state === 'active') {
                return;
              }

              if (
                user.membership_type === 'group_member' ||
                user.membership_type === 'project_member'
              ) {
                expect(serializedRow.toggle.disabled).toBe(true);
                expect(serializedRow.toggle.title).toBe(
                  'To make this member active, you must first remove an existing active member, or toggle them to over limit.',
                );
              }
            });
          });

          it('sets toggle props correctly for the current user', () => {
            forEachUser((user, serializedRow) => {
              if (user.id !== gon.current_user_id) {
                return;
              }

              expect(serializedRow.toggle.disabled).toBe(true);
              expect(serializedRow.toggle.title).toBe(
                "You can't remove yourself from a seat, but you can leave the group.",
              );
            });
          });

          it('sets toggle props correctly for active group or project members', () => {
            forEachUser((user, serializedRow) => {
              if (
                user.membership_state === 'awaiting' ||
                user.is_last_owner ||
                user.id === gon.current_user_id
              ) {
                return;
              }

              if (
                user.membership_type === 'group_member' ||
                user.membership_type === 'project_member'
              ) {
                expect(serializedRow.toggle.disabled).toBe(false);
                expect(serializedRow.toggle.title).toBe('');
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
              usageValue: '10',
              helpTooltip: null,
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
        });

        describe('when preview free user cap', () => {
          beforeEach(() => {
            wrapper = createComponent({
              initialState: {
                ...defaultInitialState,
                hasNoSubscription: true,
                hasLimitedFreePlan: false,
                previewFreeUserCap: true,
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
        });
      });
    });

    describe('for free namespace with free user cap preview enabled', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialState: {
            hasNoSubscription: true,
            hasLimitedFreePlan: false,
            previewFreeUserCap: true,
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
        });
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
      pendingMembersPagePath | pendingMembersCount | hasLimitedFreePlan | previewFreeUserCap | shouldBeRendered
      ${undefined}           | ${undefined}        | ${false}           | ${false}           | ${false}
      ${undefined}           | ${0}                | ${false}           | ${false}           | ${false}
      ${'fake-path'}         | ${0}                | ${false}           | ${false}           | ${false}
      ${'fake-path'}         | ${3}                | ${true}            | ${false}           | ${false}
      ${'fake-path'}         | ${3}                | ${false}           | ${true}            | ${false}
      ${'fake-path'}         | ${3}                | ${false}           | ${false}           | ${true}
    `(
      'rendering alert is $shouldBeRendered when pendingMembersPagePath=$pendingMembersPagePath and pendingMembersCount=$pendingMembersCount and hasLimitedFreePlan=$hasLimitedFreePlan and previewFreeUserCap=$previewFreeUserCap',
      ({
        pendingMembersPagePath,
        pendingMembersCount,
        shouldBeRendered,
        hasLimitedFreePlan,
        previewFreeUserCap,
      }) => {
        wrapper = createComponent({
          initialState: {
            pendingMembersCount,
            pendingMembersPagePath,
            hasLimitedFreePlan,
            previewFreeUserCap,
          },
        });

        expect(wrapper.find('[data-testid="pending-members-alert"]').exists()).toBe(
          shouldBeRendered,
        );
      },
    );
  });

  describe('seats alert banner', () => {
    let originalAlertBannerCookie;
    let trackingSpy;

    beforeEach(() => {
      originalAlertBannerCookie = getCookie(DISMISS_SEATS_ALERT_COOKIE_NAME);
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      wrapper.destroy();
      setCookie(DISMISS_SEATS_ALERT_COOKIE_NAME, originalAlertBannerCookie);
    });

    it('renders page without the banner and does not track', () => {
      wrapper = createComponent();

      expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'render', {
        label: RENDER_SEATS_PAGE_TRACK_LABEL,
      });

      expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'render', {
        label: RENDER_SEATS_ALERT_TRACK_LABEL,
      });

      expect(findSeatsAlertBanner().exists()).toBe(false);
    });

    describe('when previewFreeUserCap is enabled and alert is dismissed', () => {
      it('renders page without the banner and tracks events', () => {
        setCookie(DISMISS_SEATS_ALERT_COOKIE_NAME, 'true');
        wrapper = createComponent({ initialState: { previewFreeUserCap: true } });

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
          label: RENDER_SEATS_PAGE_TRACK_LABEL,
        });
        expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'render', {
          label: RENDER_SEATS_ALERT_TRACK_LABEL,
        });
        expect(findSeatsAlertBanner().exists()).toBe(false);
      });
    });

    describe('when alert is not dismissed', () => {
      it('renders page without the banner', () => {
        setCookie(DISMISS_SEATS_ALERT_COOKIE_NAME, 'false');
        wrapper = createComponent();

        expect(findSeatsAlertBanner().exists()).toBe(false);
      });
    });

    describe('when previewFreeUserCap is enabled and alert is not dismissed', () => {
      it('renders page with the banner and tracks events', () => {
        setCookie(DISMISS_SEATS_ALERT_COOKIE_NAME, 'false');
        wrapper = createComponent({ initialState: { previewFreeUserCap: true } });

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
          label: RENDER_SEATS_PAGE_TRACK_LABEL,
        });
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
          label: RENDER_SEATS_ALERT_TRACK_LABEL,
        });

        expect(findSeatsAlertBanner().props('title')).toEqual(
          'From October 19, 2022, free groups will be limited to 5 members',
        );

        expect(findSeatsAlertBanner().text()).toContain(
          "You can begin moving members in Test Group Name now. A member loses access to the group when you turn off In a seat. If over 5 members have In a seat enabled after October 19, 2022, we'll select the 5 members who maintain access. We'll first count members that have Owner and Maintainer roles, then the most recently active members until we reach 5 members. The remaining members will get a status of Over limit and lose access to the group.",
        );
      });
    });

    describe('dismiss', () => {
      it('sets cookie and tracks dismiss', () => {
        setCookie(DISMISS_SEATS_ALERT_COOKIE_NAME, 'false');
        wrapper = createComponent({ initialState: { previewFreeUserCap: true } });

        expect(wrapper.vm.isDismissedSeatsAlert).toBe(false);

        findSeatsAlertBanner().vm.$emit('dismiss');

        expect(getCookie(DISMISS_SEATS_ALERT_COOKIE_NAME)).toBe('true');
        expect(wrapper.vm.isDismissedSeatsAlert).toBe(true);

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'dismiss', {
          label: DISMISS_SEATS_ALERT_TRACK_LABEL,
        });
      });
    });
  });
});
