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
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import createMockApollo from 'helpers/mock_apollo_helper';
import SubscriptionUserList from 'ee/usage_quotas/seats/components/subscription_user_list.vue';
import {
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
  SORT_OPTIONS,
} from 'ee/usage_quotas/seats/constants';
import waitForPromises from 'helpers/wait_for_promises';
import {
  mockTableItems,
  assignedAddonData,
  noPurchasedAddonData,
  mockTableItemsWithCodeSuggestionsAddOn,
} from 'ee_jest/usage_quotas/seats/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SearchAndSortBar from 'ee/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import addOnPurchaseQuery from 'ee/usage_quotas/graphql/queries/get_add_on_purchase_query.graphql';
import CodeSuggestionsAddOnAssignment from 'ee/usage_quotas/seats/components/code_suggestions_addon_assignment.vue';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';

Vue.use(Vuex);
Vue.use(VueApollo);

const actionSpies = {
  setBillableMemberToRemove: jest.fn(),
  setSearchQuery: jest.fn(),
};

const MOCK_SEAT_USAGE_EXPORT_PATH = '/groups/test_group/-/seat_usage.csv';

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
      namespaceId: '1',
      total: 300,
      page: 1,
      perPage: 5,
      sort: 'last_activity_on_desc',
      seatUsageExportPath: MOCK_SEAT_USAGE_EXPORT_PATH,
      ...initialState,
    },
  });

describe('Subscription User List', () => {
  let wrapper;

  const fullPath = 'namespace/full-path';

  const assignedAddonDataHandler = jest.fn().mockResolvedValue(assignedAddonData);
  const noPurchasedAddonDataHandler = jest.fn().mockResolvedValue(noPurchasedAddonData);
  const addonPurchaseErrorDataHandler = jest.fn().mockRejectedValue(new Error('Error'));

  const createMockApolloProvider = (handler = noPurchasedAddonDataHandler) =>
    createMockApollo([[addOnPurchaseQuery, handler]]);

  const createComponent = ({
    initialState = {},
    mountFn = shallowMount,
    initialGetters = {},
    provide = {},
    handler,
  } = {}) => {
    wrapper = extendedWrapper(
      mountFn(SubscriptionUserList, {
        apolloProvider: createMockApolloProvider(handler),
        store: fakeStore({ initialState, initialGetters }),
        provide: {
          fullPath,
          glFeatures: {
            enableHamiltonInUsageQuotasUi: false,
          },
          ...provide,
        },
      }),
    );

    return waitForPromises();
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findExportButton = () => wrapper.findByTestId('export-button');
  const findSearchAndSortBar = () => wrapper.findComponent(SearchAndSortBar);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findAllRemoveUserItems = () => wrapper.findAllByTestId('remove-user');
  const findErrorModal = () => wrapper.findComponent(GlModal);
  const findAllCodeSuggestionsAddonComponents = () =>
    wrapper.findAllComponents(CodeSuggestionsAddOnAssignment);
  const findAddOnError = () => wrapper.findComponent(ErrorAlert);

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

  describe('renders', () => {
    beforeEach(async () => {
      await createComponent({
        mountFn: mount,
        initialGetters: {
          tableItems: () => mockTableItems,
        },
      });
    });

    describe('export button', () => {
      it('has the correct href', () => {
        expect(findExportButton().attributes().href).toBe(MOCK_SEAT_USAGE_EXPORT_PATH);
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

  describe('Loading state', () => {
    describe('When nothing is loading', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('displays the table in a non-busy state', () => {
        expect(findTable().attributes('busy')).toBe(undefined);
      });
    });

    describe.each([
      [true, false],
      [false, true],
    ])('Busy when isLoading=%s and hasError=%s', (isLoading, hasError) => {
      beforeEach(async () => {
        await createComponent({
          initialGetters: { isLoading: () => isLoading },
          initialState: { hasError },
        });
      });

      it('displays table in busy state', () => {
        expect(findTable().attributes('busy')).toBe('true');
      });
    });
  });

  describe('search box', () => {
    beforeEach(async () => {
      await createComponent();
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

  describe('code suggestions addon', () => {
    describe('with `enableHamiltonInUsageQuotasUi` enabled', () => {
      const commonProps = {
        mountFn: mount,
        provide: {
          glFeatures: {
            enableHamiltonInUsageQuotasUi: true,
          },
        },
      };

      const salesLink = `${PROMO_URL}/sales/`;
      const supportLink = `${PROMO_URL}/support/`;
      const expectedErrorDictionaryProp = {
        add_on_purchase_fetch_error: {
          links: { supportLink },
          message:
            'An error occurred while loading details for the Code Suggestions add-on. If the problem persists, please %{supportLinkStart}contact support%{supportLinkEnd}.',
        },
        cannot_assign_addon: {
          links: { supportLink },
          message:
            'Something went wrong when assigning the add-on to this member. If the problem persists, please %{supportLinkStart}contact support%{supportLinkEnd}.',
          title: 'Error assigning Code Suggestions add-on',
        },
        cannot_unassign_addon: {
          links: { supportLink },
          message:
            'Something went wrong when un-assigning the add-on to this member. If the problem persists, please %{supportLinkStart}contact support%{supportLinkEnd}.',
          title: 'Error un-assigning Code Suggestions add-on',
        },
        no_seats_available: {
          links: { salesLink },
          message:
            'You have assigned all available Code Suggestions add-on seats. Please %{salesLinkStart}contact sales%{salesLinkEnd} if you would like to purchase more seats.',
          title: 'No seats available',
        },
      };

      describe('when there is a paid subscription', () => {
        describe('when there are purchased addons', () => {
          beforeEach(async () => {
            await createComponent({
              ...commonProps,
              initialState: {
                hasNoSubscription: false,
              },
              initialGetters: {
                tableItems: () => mockTableItemsWithCodeSuggestionsAddOn,
              },
              handler: assignedAddonDataHandler,
            });
          });

          it('shows code suggestions addon field', () => {
            const expectedProps = mockTableItemsWithCodeSuggestionsAddOn.map((item) => ({
              userId: item.user.id,
              addOns: item.user.add_ons,
            }));
            const actualProps = findAllCodeSuggestionsAddonComponents().wrappers.map((item) => ({
              userId: item.props('userId'),
              addOns: item.props('addOns'),
            }));

            expect(actualProps).toEqual(expectedProps);
          });

          it('calls addOnPurchaseQuery with appropriate params', () => {
            expect(assignedAddonDataHandler).toHaveBeenCalledWith({
              fullPath,
              addOnName: 'CODE_SUGGESTIONS',
            });
          });
        });

        describe('when there are no purchased addons', () => {
          beforeEach(async () => {
            await createComponent({
              ...commonProps,
              initialState: {
                hasNoSubscription: false,
              },
              handler: noPurchasedAddonDataHandler,
            });
          });

          it('does not show code suggestions addon field', () => {
            expect(findAllCodeSuggestionsAddonComponents().length).toBe(0);
          });

          it('calls addOnPurchaseQuery with appropriate params', () => {
            expect(noPurchasedAddonDataHandler).toHaveBeenCalledWith({
              fullPath,
              addOnName: 'CODE_SUGGESTIONS',
            });
          });
        });
      });

      describe('when there is no paid subscription', () => {
        beforeEach(async () => {
          await createComponent({
            ...commonProps,
            initialState: {
              hasNoSubscription: true,
            },
            handler: assignedAddonDataHandler,
          });
        });

        it('does not show code suggestions addon field', () => {
          expect(findAllCodeSuggestionsAddonComponents().length).toBe(0);
        });

        it('does not call addOnPurchaseQuery', () => {
          expect(assignedAddonDataHandler).not.toHaveBeenCalled();
        });
      });

      describe('when there is an error while fetching addon details', () => {
        beforeEach(async () => {
          await createComponent({
            ...commonProps,
            initialState: {
              hasNoSubscription: false,
            },
            handler: addonPurchaseErrorDataHandler,
          });
        });

        it('shows an error alert', () => {
          const expectedProps = {
            dismissible: true,
            error: 'ADD_ON_PURCHASE_FETCH_ERROR',
            errorDictionary: expectedErrorDictionaryProp,
          };
          expect(findAddOnError().props()).toEqual(expect.objectContaining(expectedProps));
        });

        it('clears error alert when dismissed', async () => {
          findAddOnError().vm.$emit('dismiss');

          await nextTick();

          expect(findAddOnError().exists()).toBe(false);
        });

        it('does not show code suggestions addon field', () => {
          expect(findAllCodeSuggestionsAddonComponents().length).toBe(0);
        });
      });

      describe('when there is an error while assigning addon', () => {
        const addOnAssignmentError = 'NO_SEATS_AVAILABLE';
        beforeEach(async () => {
          await createComponent({
            ...commonProps,
            initialState: {
              hasNoSubscription: false,
            },
            initialGetters: {
              tableItems: () => mockTableItemsWithCodeSuggestionsAddOn,
            },
            handler: assignedAddonDataHandler,
          });
          findAllCodeSuggestionsAddonComponents()
            .at(0)
            .vm.$emit('handleAddOnAssignmentError', addOnAssignmentError);
        });

        it('shows an error alert', () => {
          const expectedProps = {
            dismissible: true,
            error: addOnAssignmentError,
            errorDictionary: expectedErrorDictionaryProp,
          };
          expect(findAddOnError().props()).toEqual(expect.objectContaining(expectedProps));
        });

        it('clears error alert when dismissed', async () => {
          findAddOnError().vm.$emit('dismiss');

          await nextTick();

          expect(findAddOnError().exists()).toBe(false);
        });
      });
    });

    describe('with `enableHamiltonInUsageQuotasUi` disabled', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mount,
          provide: {
            glFeatures: {
              enableHamiltonInUsageQuotasUi: false,
            },
          },
          initialState: {
            hasNoSubscription: false,
          },
          handler: assignedAddonDataHandler,
        });
      });

      it('does not show code suggestions addon field', () => {
        expect(findAllCodeSuggestionsAddonComponents().length).toBe(0);
      });

      it('does not call addOnPurchaseQuery', () => {
        expect(assignedAddonDataHandler).not.toHaveBeenCalled();
      });
    });
  });
});
