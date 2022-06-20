import MockAdapter from 'axios-mock-adapter';
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
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

jest.mock('~/flash');

describe('seats actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = State();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('fetchBillableMembersList', () => {
    let spy;
    const payload = {
      page: 5,
      search: 'search string',
      sort: 'last_activity_on_desc',
      include_awaiting_members: false,
    };

    beforeEach(() => {
      gon.api_version = 'v4';

      state = Object.assign(state, {
        namespaceId: 1,
        page: 5,
        search: 'search string',
        sort: 'last_activity_on_desc',
        hasLimitedFreePlan: false,
        previewFreeUserCap: false,
        hasNoSubscription: false,
      });

      spy = jest.spyOn(GroupsApi, 'fetchBillableGroupMembersList');
    });

    it('passes correct arguments to Api call', () => {
      testAction({
        action: actions.fetchBillableMembersList,
        payload,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(spy).toBeCalledWith(state.namespaceId, expect.objectContaining(payload));
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

      expect(spy).toBeCalledWith(
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

      expect(spy).toBeCalledWith(
        state.namespaceId,
        expect.objectContaining({ ...payload, include_awaiting_members: true }),
      );
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet('/api/v4/groups/1/billable_members')
          .replyOnce(httpStatusCodes.OK, mockDataSeats.data, mockDataSeats.headers);
      });

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
      beforeEach(() => {
        mock.onGet('/api/v4/groups/1/billable_members').replyOnce(httpStatusCodes.NOT_FOUND, {});
      });

      it('should dispatch the request and error actions', () => {
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
      gon.api_version = 'v4';
      state.namespaceId = 1;
    });

    it('passes correct arguments to Api call', () => {
      const spy = jest.spyOn(Api, 'userSubscription');

      testAction({
        action: actions.fetchGitlabSubscription,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(spy).toBeCalledWith(state.namespaceId);
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet('/api/v4/namespaces/1/gitlab_subscription')
          .replyOnce(httpStatusCodes.OK, mockUserSubscription);
      });

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
      beforeEach(() => {
        mock
          .onGet('/api/v4/namespaces/1/gitlab_subscription')
          .replyOnce(httpStatusCodes.NOT_FOUND, {});
      });

      it('should dispatch the request and error actions', () => {
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

  describe('resetBillableMembers', () => {
    it('should commit mutation', () => {
      testAction({
        action: actions.resetBillableMembers,
        state,
        expectedMutations: [{ type: types.RESET_BILLABLE_MEMBERS }],
      });
    });
  });

  describe('setBillableMemberToRemove', () => {
    it('should commit the set member mutation', async () => {
      await testAction({
        action: actions.setBillableMemberToRemove,
        state,
        expectedMutations: [{ type: types.SET_BILLABLE_MEMBER_TO_REMOVE }],
      });
    });
  });

  describe('removeBillableMember', () => {
    let groupsApiSpy;

    beforeEach(() => {
      groupsApiSpy = jest.spyOn(GroupsApi, 'removeBillableMemberFromGroup');

      state = {
        namespaceId: 1,
        billableMemberToRemove: {
          id: 2,
        },
      };
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onDelete('/api/v4/groups/1/billable_members/2').reply(httpStatusCodes.OK);
      });

      it('dispatches the removeBillableMemberSuccess action', async () => {
        await testAction({
          action: actions.removeBillableMember,
          state,
          expectedActions: [{ type: 'removeBillableMemberSuccess' }],
        });

        expect(groupsApiSpy).toHaveBeenCalled();
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock
          .onDelete('/api/v4/groups/1/billable_members/2')
          .reply(httpStatusCodes.UNPROCESSABLE_ENTITY);
      });

      it('dispatches the removeBillableMemberError action', async () => {
        await testAction({
          action: actions.removeBillableMember,
          state,
          expectedActions: [{ type: 'removeBillableMemberError' }],
        });

        expect(groupsApiSpy).toHaveBeenCalled();
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

    afterEach(() => {
      mock.reset();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onPut('/api/v4/groups/1/members/2/state')
          .replyOnce(httpStatusCodes.OK, { success: true });

        expectedActions = [
          { type: 'fetchBillableMembersList' },
          { type: 'fetchGitlabSubscription' },
        ];

        expectedMutations = [{ type: types.CHANGE_MEMBERSHIP_STATE }];
      });

      describe('for an active user', () => {
        it('passes correct arguments to Api call for an active user', () => {
          const spy = jest.spyOn(GroupsApi, 'changeMembershipState');

          jest.spyOn(GroupsApi, 'fetchBillableGroupMembersList');
          jest.spyOn(Api, 'userSubscription');

          testAction({
            action: actions.changeMembershipState,
            payload: user,
            state,
            expectedMutations,
            expectedActions,
          });

          expect(spy).toBeCalledWith(state.namespaceId, user.id, MEMBER_AWAITING_STATE);
        });
      });

      describe('for an awaiting user', () => {
        it('passes correct arguments to Api call for an active user', () => {
          const spy = jest.spyOn(GroupsApi, 'changeMembershipState');

          testAction({
            action: actions.changeMembershipState,
            payload: { ...user, membership_state: MEMBER_AWAITING_STATE },
            state,
            expectedMutations,
            expectedActions,
          });

          expect(spy).toBeCalledWith(state.namespaceId, user.id, MEMBER_ACTIVE_STATE);
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock
          .onPut('/api/v4/groups/1/members/2/state')
          .replyOnce(httpStatusCodes.UNPROCESSABLE_ENTITY, {});
      });

      it('should dispatch the request and error actions', async () => {
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

  describe('changeMembershipStateError', () => {
    it('ccommits mutation and calls createAlert', async () => {
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
      GroupsApi.fetchBillableGroupMemberMemberships = jest
        .fn()
        .mockResolvedValue({ data: mockMemberDetails });
    });

    it('commits fetchBillableMemberDetails', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetails,
        payload: member.id,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS, payload: member.id },
          {
            type: types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS,
            payload: { memberId: member.id, memberships: mockMemberDetails },
          },
        ],
      });
    });

    it('calls fetchBillableGroupMemberMemberships api', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetails,
        payload: member.id,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS, payload: member.id },
          {
            type: types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS,
            payload: { memberId: member.id, memberships: mockMemberDetails },
          },
        ],
      });

      expect(GroupsApi.fetchBillableGroupMemberMemberships).toHaveBeenCalledWith(null, 2);
    });

    it('calls fetchBillableGroupMemberMemberships api only once', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetails,
        payload: member.id,
        state,
        expectedMutations: [
          { type: types.FETCH_BILLABLE_MEMBER_DETAILS, payload: member.id },
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
      beforeAll(() => {
        GroupsApi.fetchBillableGroupMemberMemberships = jest.fn().mockRejectedValue();
      });

      it('dispatches fetchBillableMemberDetailsError', async () => {
        await testAction({
          action: actions.fetchBillableMemberDetailsError,
          state,
          expectedMutations: [{ type: types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR }],
        });
      });
    });
  });

  describe('fetchBillableMemberDetailsError', () => {
    it('commits fetch billable member details error', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetailsError,
        state,
        expectedMutations: [{ type: types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR }],
      });
    });

    it('calls createAlert', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetailsError,
        state,
        expectedMutations: [{ type: types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR }],
      });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while getting a billable member details.',
      });
    });
  });
});
