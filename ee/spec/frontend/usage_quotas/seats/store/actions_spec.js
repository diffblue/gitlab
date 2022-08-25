import * as GroupsApi from 'ee/api/groups_api';
import Api from 'ee/api';
import * as actions from 'ee/usage_quotas/seats/store/actions';
import { MEMBER_ACTIVE_STATE, MEMBER_AWAITING_STATE } from 'ee/usage_quotas/seats/constants';
import * as types from 'ee/usage_quotas/seats/store/mutation_types';
import State from 'ee/usage_quotas/seats/store/state';
import {
  mockDataSeats,
  mockMemberDetails,
  mockUserSubscription,
} from 'ee_jest/usage_quotas/seats/mock_data';
import testAction from 'helpers/vuex_action_helper';
import { createAlert, VARIANT_SUCCESS } from '~/flash';

jest.mock('ee/api/groups_api');
jest.mock('ee/api');
jest.mock('~/flash');

describe('Usage Quotas Seats actions', () => {
  let state;

  beforeEach(() => {
    state = State();
  });

  describe('fetchBillableMembersList', () => {
    const payload = {
      page: 5,
      search: 'search string',
      sort: 'last_activity_on_desc',
      include_awaiting_members: false,
    };

    beforeEach(() => {
      state = Object.assign(state, {
        namespaceId: 1,
        page: 5,
        search: 'search string',
        sort: 'last_activity_on_desc',
        hasLimitedFreePlan: false,
        previewFreeUserCap: false,
        hasNoSubscription: false,
      });

      GroupsApi.fetchBillableGroupMembersList.mockResolvedValue({
        data: mockDataSeats.data,
        headers: mockDataSeats.headers,
      });
    });

    it('passes correct arguments to Api call', () => {
      testAction({
        action: actions.fetchBillableMembersList,
        payload,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(GroupsApi.fetchBillableGroupMembersList).toBeCalledWith(
        state.namespaceId,
        expect.objectContaining(payload),
      );
    });

    it('queries awaiting members when on limited free plan', () => {
      state = Object.assign(state, {
        ...payload,
        hasLimitedFreePlan: true,
        hasNoSubscription: true,
      });

      testAction({
        action: actions.fetchBillableMembersList,
        payload,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(GroupsApi.fetchBillableGroupMembersList).toBeCalledWith(
        state.namespaceId,
        expect.objectContaining({ ...payload, include_awaiting_members: true }),
      );
    });

    it('queries awaiting members when previewFreeCap is enabled', () => {
      state = Object.assign(state, {
        ...payload,
        previewFreeUserCap: true,
        hasNoSubscription: true,
      });

      testAction({
        action: actions.fetchBillableMembersList,
        payload,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(GroupsApi.fetchBillableGroupMembersList).toBeCalledWith(
        state.namespaceId,
        expect.objectContaining({ ...payload, include_awaiting_members: true }),
      );
    });

    describe('on success', () => {
      it('should dispatch the request and success actions', () => {
        testAction({
          action: actions.fetchBillableMembersList,
          state,
          expectedActions: [
            {
              type: 'receiveBillableMembersListSuccess',
              payload: mockDataSeats,
            },
          ],
          expectedMutations: [{ type: types.REQUEST_BILLABLE_MEMBERS }],
        });
      });
    });

    describe('on error', () => {
      it('should dispatch the request and error actions', () => {
        GroupsApi.fetchBillableGroupMembersList.mockRejectedValue();

        testAction({
          action: actions.fetchBillableMembersList,
          state,
          expectedActions: [{ type: 'receiveBillableMembersListError' }],
          expectedMutations: [{ type: types.REQUEST_BILLABLE_MEMBERS }],
        });
      });
    });
  });

  describe('receiveBillableMembersListSuccess', () => {
    it('should commit the success mutation', () => {
      testAction({
        action: actions.receiveBillableMembersListSuccess,
        payload: mockDataSeats,
        state,
        expectedMutations: [
          { type: types.RECEIVE_BILLABLE_MEMBERS_SUCCESS, payload: mockDataSeats },
        ],
      });
    });
  });

  describe('receiveBillableMembersListError', () => {
    it('should commit the error mutation', async () => {
      await testAction({
        action: actions.receiveBillableMembersListError,
        state,
        expectedMutations: [{ type: types.RECEIVE_BILLABLE_MEMBERS_ERROR }],
      });

      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('fetchGitlabSubscription', () => {
    beforeEach(() => {
      state.namespaceId = 1;
      Api.userSubscription.mockResolvedValue({ data: mockUserSubscription });
    });

    it('passes correct arguments to Api call', () => {
      testAction({
        action: actions.fetchGitlabSubscription,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(Api.userSubscription).toBeCalledWith(state.namespaceId);
    });

    describe('on success', () => {
      it('should dispatch the request and success actions', () => {
        testAction({
          action: actions.fetchGitlabSubscription,
          state,
          expectedActions: [
            {
              type: 'receiveGitlabSubscriptionSuccess',
              payload: mockUserSubscription,
            },
          ],
          expectedMutations: [{ type: types.REQUEST_GITLAB_SUBSCRIPTION }],
        });
      });
    });

    describe('on error', () => {
      it('should dispatch the request and error actions', () => {
        Api.userSubscription.mockRejectedValue();

        testAction({
          action: actions.fetchGitlabSubscription,
          state,
          expectedActions: [{ type: 'receiveGitlabSubscriptionError' }],
          expectedMutations: [{ type: types.REQUEST_GITLAB_SUBSCRIPTION }],
        });
      });
    });
  });

  describe('receiveGitlabSubscriptionSuccess', () => {
    it('should commit the success mutation', () => {
      testAction({
        action: actions.receiveGitlabSubscriptionSuccess,
        payload: mockDataSeats,
        state,
        expectedMutations: [
          { type: types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS, payload: mockDataSeats },
        ],
      });
    });
  });

  describe('receiveGitlabSubscriptionError', () => {
    it('should commit the error mutation', async () => {
      await testAction({
        action: actions.receiveGitlabSubscriptionError,
        state,
        expectedMutations: [{ type: types.RECEIVE_GITLAB_SUBSCRIPTION_ERROR }],
      });

      expect(createAlert).toHaveBeenCalled();
    });
  });

  describe('setBillableMemberToRemove', () => {
    it('should commit the set member mutation', async () => {
      const member = { id: 'test' };

      await testAction({
        action: actions.setBillableMemberToRemove,
        payload: member,
        state,
        expectedMutations: [{ type: types.SET_BILLABLE_MEMBER_TO_REMOVE, payload: member }],
      });
    });
  });

  describe('removeBillableMember', () => {
    beforeEach(() => {
      state = {
        namespaceId: 1,
        billableMemberToRemove: {
          id: 2,
        },
      };
    });

    describe('on success', () => {
      it('dispatches the removeBillableMemberSuccess action', async () => {
        GroupsApi.removeBillableMemberFromGroup.mockResolvedValue();

        await testAction({
          action: actions.removeBillableMember,
          state,
          expectedActions: [{ type: 'removeBillableMemberSuccess' }],
          expectedMutations: [{ type: types.REMOVE_BILLABLE_MEMBER }],
        });

        expect(GroupsApi.removeBillableMemberFromGroup).toHaveBeenCalledWith(
          state.namespaceId,
          state.billableMemberToRemove.id,
        );
      });
    });

    describe('on error', () => {
      it('dispatches the removeBillableMemberError action', async () => {
        GroupsApi.removeBillableMemberFromGroup.mockRejectedValue();

        await testAction({
          action: actions.removeBillableMember,
          state,
          expectedActions: [{ type: 'removeBillableMemberError' }],
          expectedMutations: [{ type: types.REMOVE_BILLABLE_MEMBER }],
        });

        expect(GroupsApi.removeBillableMemberFromGroup).toHaveBeenCalled();
      });
    });
  });

  describe('removeBillableMemberSuccess', () => {
    it('dispatches fetchBillableMembersList', async () => {
      await testAction({
        action: actions.removeBillableMemberSuccess,
        state,
        expectedActions: [
          { type: 'fetchBillableMembersList' },
          { type: 'fetchGitlabSubscription' },
        ],

        expectedMutations: [{ type: types.REMOVE_BILLABLE_MEMBER_SUCCESS }],
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'User was successfully removed',
        variant: VARIANT_SUCCESS,
      });
    });
  });

  describe('removeBillableMemberError', () => {
    it('commits remove member error', async () => {
      await testAction({
        action: actions.removeBillableMemberError,
        state,
        expectedMutations: [{ type: types.REMOVE_BILLABLE_MEMBER_ERROR }],
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while removing a billable member.',
      });
    });
  });

  describe('changeMembershipState', () => {
    let user;
    let expectedActions;
    let expectedMutations;

    beforeEach(() => {
      state.namespaceId = 1;
      user = { id: 2, membership_state: MEMBER_ACTIVE_STATE };
    });

    describe('Group API call', () => {
      beforeEach(() => {
        expectedMutations = [{ type: types.CHANGE_MEMBERSHIP_STATE }];

        expectedActions = [{ type: 'changeMembershipStateSuccess' }];
      });

      describe('for an active user', () => {
        it('passes correct arguments to Api call for an active user', () => {
          testAction({
            action: actions.changeMembershipState,
            payload: user,
            state,
            expectedMutations,
            expectedActions,
          });

          expect(GroupsApi.changeMembershipState).toBeCalledWith(
            state.namespaceId,
            user.id,
            MEMBER_AWAITING_STATE,
          );
        });
      });

      describe('for an awaiting user', () => {
        it('passes correct arguments to Api call for an active user', () => {
          testAction({
            action: actions.changeMembershipState,
            payload: { ...user, membership_state: MEMBER_AWAITING_STATE },
            state,
            expectedMutations,
            expectedActions,
          });

          expect(GroupsApi.changeMembershipState).toBeCalledWith(
            state.namespaceId,
            user.id,
            MEMBER_ACTIVE_STATE,
          );
        });
      });
    });

    describe('on error', () => {
      it('should dispatch the request and error actions', async () => {
        GroupsApi.changeMembershipState.mockRejectedValue();

        await testAction({
          action: actions.changeMembershipState,
          payload: user,
          state,
          expectedMutations: [{ type: types.CHANGE_MEMBERSHIP_STATE }],
          expectedActions: [{ type: 'changeMembershipStateError' }],
        });
      });
    });
  });

  describe('changeMembershipStateSuccess', () => {
    it('should dispatch billable members list and GitLab subscription', () => {
      testAction({
        action: actions.changeMembershipStateSuccess,
        state,
        expectedMutations: [
          {
            type: types.CHANGE_MEMBERSHIP_STATE_SUCCESS,
          },
        ],
        expectedActions: [
          { type: 'fetchBillableMembersList' },
          { type: 'fetchGitlabSubscription' },
        ],
      });
    });
  });

  describe('changeMembershipStateError', () => {
    it('commits mutation and calls createAlert', async () => {
      await testAction({
        action: actions.changeMembershipStateError,
        state,
        expectedMutations: [{ type: types.CHANGE_MEMBERSHIP_STATE_ERROR }],
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong. Please try again.',
      });
    });
  });

  describe('fetchBillableMemberDetails', () => {
    const member = mockDataSeats.data[0];

    beforeAll(() => {
      GroupsApi.fetchBillableGroupMemberMemberships.mockResolvedValue({ data: mockMemberDetails });
    });

    it('commits fetchBillableMemberDetails', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetails,
        payload: member.id,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS, payload: { memberId: member.id } },
          {
            type: types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS,
            payload: { memberId: member.id, memberships: mockMemberDetails },
          },
        ],
      });
    });

    it('calls fetchBillableGroupMemberMemberships API', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetails,
        payload: member.id,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS, payload: { memberId: member.id } },
          {
            type: types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS,
            payload: { memberId: member.id, memberships: mockMemberDetails },
          },
        ],
      });

      expect(GroupsApi.fetchBillableGroupMemberMemberships).toHaveBeenCalledWith(null, 2);
    });

    it('calls fetchBillableGroupMemberMemberships API only once', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetails,
        payload: member.id,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS, payload: { memberId: member.id } },
          {
            type: types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS,
            payload: { memberId: member.id, memberships: mockMemberDetails },
          },
        ],
      });

      state.userDetails[member.id] = { items: mockMemberDetails, isLoading: false };

      await testAction({
        action: actions.fetchBillableMemberDetails,
        payload: member.id,
        state,
        expectedMutations: [
          {
            type: types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS,
            payload: { memberId: member.id, memberships: mockMemberDetails },
          },
        ],
      });

      expect(GroupsApi.fetchBillableGroupMemberMemberships).toHaveBeenCalledTimes(1);
    });

    describe('on API error', () => {
      it('dispatches fetchBillableMemberDetailsError', async () => {
        GroupsApi.fetchBillableGroupMemberMemberships.mockRejectedValue();

        await testAction({
          action: actions.fetchBillableMemberDetails,
          payload: member.id,
          state,
          expectedMutations: [
            { type: types.FETCH_BILLABLE_MEMBER_DETAILS, payload: { memberId: member.id } },
          ],
          expectedActions: [{ type: 'fetchBillableMemberDetailsError', payload: member.id }],
        });
      });
    });
  });

  describe('fetchBillableMemberDetailsError', () => {
    const memberId = 42;

    it('commits fetch billable member details error', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetailsError,
        payload: memberId,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR, payload: { memberId } },
        ],
      });
    });

    it('calls createAlert', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetailsError,
        payload: memberId,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR, payload: { memberId } },
        ],
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while getting a billable member details.',
      });
    });
  });
});
