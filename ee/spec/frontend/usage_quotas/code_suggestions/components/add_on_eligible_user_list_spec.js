import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlSkeletonLoader,
  GlKeysetPagination,
  GlTable,
} from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '@sentry/browser';
import CodeSuggestionsAddOnAssignment from 'ee/usage_quotas/code_suggestions/components/code_suggestions_addon_assignment.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import AddOnEligibleUserList from 'ee/usage_quotas/code_suggestions/components/add_on_eligible_user_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import {
  mockAddOnEligibleUsers,
  mockNoAddOnEligibleUsers,
  mockPaginatedAddOnEligibleUsers,
} from 'ee_jest/usage_quotas/code_suggestions/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import getAddOnEligibleUsers from 'ee/usage_quotas/add_on/graphql/add_on_eligible_users.query.graphql';
import {
  ADD_ON_ELIGIBLE_USERS_FETCH_ERROR_CODE,
  ADD_ON_ERROR_DICTIONARY,
} from 'ee/usage_quotas/error_constants';
import { scrollToElement } from '~/lib/utils/common_utils';

jest.mock('~/lib/utils/common_utils');

Vue.use(VueApollo);

jest.mock('@sentry/browser');

describe('Add On Eligible User List', () => {
  let wrapper;

  const fullPath = 'namespace/full-path';
  const addOnPurchaseId = 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/1';
  const error = new Error('Error');
  const defaultQueryVariables = {
    fullPath,
    addOnType: 'CODE_SUGGESTIONS',
    sort: 'LAST_ACTIVITY_ON_DESC',
    addOnPurchaseIds: [addOnPurchaseId],
    first: 20,
  };

  const addOnEligibleUsersDataHandler = jest.fn().mockResolvedValue(mockAddOnEligibleUsers);
  const noAddOnEligibleUsersDataHandler = jest.fn().mockResolvedValue(mockNoAddOnEligibleUsers);
  const addOnEligibleUsersErrorHandler = jest.fn().mockRejectedValue(error);
  const paginatedAddOnEligibleUsersDataHandler = jest
    .fn()
    .mockResolvedValue(mockPaginatedAddOnEligibleUsers);

  const createMockApolloProvider = (handler = noAddOnEligibleUsersDataHandler) =>
    createMockApollo([[getAddOnEligibleUsers, handler]]);

  const createComponent = ({ mountFn = shallowMount, handler } = {}) => {
    wrapper = extendedWrapper(
      mountFn(AddOnEligibleUserList, {
        apolloProvider: createMockApolloProvider(handler),
        propsData: {
          addOnPurchaseId,
        },
        provide: {
          fullPath,
        },
      }),
    );

    return waitForPromises();
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findAllCodeSuggestionsAddonComponents = () =>
    wrapper.findAllComponents(CodeSuggestionsAddOnAssignment);
  const findAddOnEligibleUsersFetchError = () =>
    wrapper.findByTestId('add-on-eligible-users-fetch-error');
  const findAddOnAssignmentError = () => wrapper.findByTestId('add-on-assignment-error');
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

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
      lastActivityOn: rowWrapper.find('[data-testid="last_activity_on"]').text(),
    };
  };

  const findSerializedTable = (tableWrapper) => {
    return tableWrapper.findAll('tbody tr').wrappers.map(serializeTableRow);
  };

  describe('renders table', () => {
    beforeEach(async () => {
      await createComponent({
        mountFn: mount,
        handler: addOnEligibleUsersDataHandler,
      });
    });

    it('renders the correct table data', () => {
      const expectedUserListData = [
        {
          email: 'Private',
          lastActivityOn: '2023-08-25',
          tooltip: 'An email address is only visible for users with public emails.',
          user: {
            avatarLabeled: { size: '32', src: 'path/to/img_userone', text: 'User One  @userone' },
            avatarLink: { alt: 'User One', href: 'path/to/userone' },
          },
        },
        {
          email: 'Private',
          lastActivityOn: '2023-08-22',
          tooltip: 'An email address is only visible for users with public emails.',
          user: {
            avatarLabeled: { size: '32', src: 'path/to/img_usertwo', text: 'User Two  @usertwo' },
            avatarLink: { alt: 'User Two', href: 'path/to/usertwo' },
          },
        },
      ];
      const actualUserListData = findSerializedTable(findTable());

      expect(actualUserListData).toEqual(expectedUserListData);
    });

    describe('code suggestions addon', () => {
      describe('renders', () => {
        beforeEach(async () => {
          await createComponent({
            mountFn: mount,
            handler: addOnEligibleUsersDataHandler,
          });
        });

        it('shows code suggestions addon field', () => {
          const expectedProps = [
            {
              userId: 'gid://gitlab/User/1',
              addOnAssignments: [{ addOnPurchase: { name: 'CODE_SUGGESTIONS' } }],
              addOnPurchaseId,
              addOnEligibleUsersQueryVariables: defaultQueryVariables,
            },
            {
              userId: 'gid://gitlab/User/2',
              addOnAssignments: [],
              addOnPurchaseId,
              addOnEligibleUsersQueryVariables: defaultQueryVariables,
            },
          ];
          const actualProps = findAllCodeSuggestionsAddonComponents().wrappers.map((item) => ({
            userId: item.props('userId'),
            addOnAssignments: item.props('addOnAssignments'),
            addOnPurchaseId: item.props('addOnPurchaseId'),
            addOnEligibleUsersQueryVariables: item.props('addOnEligibleUsersQueryVariables'),
          }));

          expect(actualProps).toMatchObject(expectedProps);
        });

        it('calls addOnEligibleUsers query with appropriate params', () => {
          expect(addOnEligibleUsersDataHandler).toHaveBeenCalledWith(defaultQueryVariables);
        });

        describe('when there is an error fetching add on eligible users', () => {
          beforeEach(async () => {
            await createComponent({
              handler: addOnEligibleUsersErrorHandler,
            });
          });

          it('sends the error to Sentry', () => {
            expect(Sentry.captureException).toHaveBeenCalledTimes(1);
            expect(Sentry.captureException.mock.calls[0][0]).toEqual(error);
          });

          it('shows an error alert', () => {
            const expectedProps = {
              dismissible: true,
              error: ADD_ON_ELIGIBLE_USERS_FETCH_ERROR_CODE,
              errorDictionary: ADD_ON_ERROR_DICTIONARY,
            };
            expect(findAddOnEligibleUsersFetchError().props()).toEqual(
              expect.objectContaining(expectedProps),
            );
          });

          it('clears error alert when dismissed', async () => {
            findAddOnEligibleUsersFetchError().vm.$emit('dismiss');

            await nextTick();

            expect(findAddOnEligibleUsersFetchError().exists()).toBe(false);
          });
        });
      });

      describe('when there is an error while assigning addon', () => {
        const addOnAssignmentError = 'NO_SEATS_AVAILABLE';
        beforeEach(async () => {
          await createComponent({
            mountFn: mount,
            handler: addOnEligibleUsersDataHandler,
          });
          findAllCodeSuggestionsAddonComponents()
            .at(0)
            .vm.$emit('handleAddOnAssignmentError', addOnAssignmentError);
        });

        it('shows an error alert', () => {
          const expectedProps = {
            dismissible: true,
            error: addOnAssignmentError,
            errorDictionary: ADD_ON_ERROR_DICTIONARY,
          };
          expect(findAddOnAssignmentError().props()).toEqual(
            expect.objectContaining(expectedProps),
          );
        });

        it('clears error alert when dismissed', async () => {
          findAddOnAssignmentError().vm.$emit('dismiss');

          await nextTick();

          expect(findAddOnAssignmentError().exists()).toBe(false);
        });

        it('scrolls to the top of the table', () => {
          expect(scrollToElement).toHaveBeenCalled();
        });
      });
    });
  });

  describe('loading state', () => {
    describe('when not loading', () => {
      beforeEach(async () => {
        await createComponent({
          mountFn: mount,
          handler: addOnEligibleUsersDataHandler,
        });
      });

      it('displays the table in a non-busy state', () => {
        expect(findTable().attributes('busy')).toBe(undefined);
      });

      it('does not display the loading state', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });
    });

    describe('when loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('displays the table in a busy state', () => {
        expect(findTable().attributes('busy')).toBe('true');
      });

      it('displays the loading state', () => {
        expect(findSkeletonLoader().exists()).toBe(true);
      });
    });
  });

  describe('pagination', () => {
    describe('when more pages exist', () => {
      beforeEach(async () => {
        await createComponent({
          handler: paginatedAddOnEligibleUsersDataHandler,
        });
      });

      it('pagination is rendered with correct values', () => {
        expect(findPagination().props()).toMatchObject({
          hasNextPage: true,
          hasPreviousPage: true,
          startCursor: 'start-cursor',
          endCursor: 'end-cursor',
        });
      });

      it('triggers a call to addOnEligibleUsers with appropriate params on next', async () => {
        findPagination().vm.$emit('next');
        await waitForPromises();

        expect(paginatedAddOnEligibleUsersDataHandler).toHaveBeenCalledWith({
          ...defaultQueryVariables,
          nextPageCursor: 'end-cursor',
        });
      });

      it('triggers a call to addOnEligibleUsers with appropriate params on prev', async () => {
        findPagination().vm.$emit('prev');
        await waitForPromises();

        expect(paginatedAddOnEligibleUsersDataHandler).toHaveBeenLastCalledWith({
          ...defaultQueryVariables,
          first: undefined,
          last: 20,
          prevPageCursor: 'start-cursor',
        });
      });
    });

    describe('when only one page of results exists', () => {
      it('does not render pagination', async () => {
        await createComponent({
          handler: addOnEligibleUsersDataHandler,
        });

        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('when loading', () => {
      it('does not render pagination', () => {
        createComponent();

        expect(findPagination().exists()).toBe(false);
      });
    });
  });
});
