import MockAdapter from 'axios-mock-adapter';
import * as GroupsApi from 'ee/api/groups_api';
import * as actions from 'ee/billings/seat_usage/store/actions';
import * as types from 'ee/billings/seat_usage/store/mutation_types';
import State from 'ee/billings/seat_usage/store/state';
import { mockDataSeats, mockMemberDetails } from 'ee_jest/billings/mock_data';
import testAction from 'helpers/vuex_action_helper';
import createFlash, { FLASH_TYPES } from '~/flash';
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
    beforeEach(() => {
      gon.api_version = 'v4';
      state.namespaceId = 1;
    });

    it('passes correct arguments to Api call', () => {
      const payload = { page: 5, search: 'search string', sort: 'last_activity_on_desc' };
      state = Object.assign(state, payload);
      const spy = jest.spyOn(GroupsApi, 'fetchBillableGroupMembersList');

      testAction({
        action: actions.fetchBillableMembersList,
        payload,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(spy).toBeCalledWith(state.namespaceId, expect.objectContaining(payload));
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

      expect(createFlash).toHaveBeenCalled();
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
        expectedActions: [{ type: 'fetchBillableMembersList' }],
        expectedMutations: [{ type: types.REMOVE_BILLABLE_MEMBER_SUCCESS }],
      });

      expect(createFlash).toHaveBeenCalledWith({
        message: 'User was successfully removed',
        type: FLASH_TYPES.SUCCESS,
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

      expect(createFlash).toHaveBeenCalledWith({
        message: 'An error occurred while removing a billable member',
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

    it('calls createFlash', async () => {
      await testAction({
        action: actions.fetchBillableMemberDetailsError,
        state,
        expectedMutations: [{ type: types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR }],
      });

      expect(createFlash).toHaveBeenCalledWith({
        message: 'An error occurred while getting a billable member details',
      });
    });
  });
});
