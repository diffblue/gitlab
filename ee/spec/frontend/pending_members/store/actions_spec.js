import MockAdapter from 'axios-mock-adapter';
import State from 'ee/pending_members/store/state';
import * as GroupsApi from 'ee/api/groups_api';
import * as actions from 'ee/pending_members/store/actions';
import * as types from 'ee/pending_members/store/mutation_types';
import {
  PENDING_MEMBERS_LIST_ERROR,
  APPROVAL_SUCCESSFUL_MESSAGE,
  APPROVAL_ERROR_MESSAGE,
  ALL_MEMBERS_APPROVAL_SUCCESSFUL_MESSAGE,
  ALL_MEMBERS_APPROVAL_ERROR_MESSAGE,
} from 'ee/pending_members/constants';
import { mockDataMembers } from 'ee_jest/pending_members/mock_data';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';

describe('Pending members actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = State();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('fetchPendingGroupMembersList', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
      state.namespaceId = 1;
    });

    it('passes correct arguments to API call', () => {
      const payload = { page: 5 };
      state = Object.assign(state, payload);
      const spy = jest.spyOn(GroupsApi, 'fetchPendingGroupMembersList');

      testAction({
        action: actions.fetchPendingMembersList,
        payload,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(spy).toHaveBeenCalledWith(state.namespaceId, expect.objectContaining(payload));
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet('/api/v4/groups/1/pending_members')
          .replyOnce(HTTP_STATUS_OK, mockDataMembers.data, mockDataMembers.headers);
      });

      it('dispatches the request and success action', () => {
        testAction({
          action: actions.fetchPendingMembersList,
          state,
          expectedMutations: [
            { type: types.REQUEST_PENDING_MEMBERS },
            { type: types.RECEIVE_PENDING_MEMBERS_SUCCESS, payload: mockDataMembers },
          ],
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet('/api/v4/groups/1/pending_members').replyOnce(HTTP_STATUS_NOT_FOUND, {});
      });

      it('dispatches the request and error action', async () => {
        const mockShowAlertPayload = {
          alertMessage: PENDING_MEMBERS_LIST_ERROR,
          alertVariant: 'danger',
        };

        await testAction({
          action: actions.fetchPendingMembersList,
          state,
          expectedMutations: [
            { type: types.REQUEST_PENDING_MEMBERS },
            { type: types.RECEIVE_PENDING_MEMBERS_ERROR },
            { type: types.SHOW_ALERT, payload: mockShowAlertPayload },
          ],
        });
      });
    });
  });

  describe('approveMember', () => {
    const memberId = 2;

    beforeEach(() => {
      gon.api_version = 'v4';
      state.namespaceId = 1;
    });

    it('passes correct arguments to API call', () => {
      const spy = jest.spyOn(GroupsApi, 'approvePendingGroupMember');

      testAction({
        action: actions.approveMember,
        payload: memberId,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(spy).toHaveBeenCalledWith(state.namespaceId, memberId);
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onPut(`/api/v4/groups/1/members/${memberId}/approve`)
          .replyOnce(HTTP_STATUS_NO_CONTENT);
      });

      it('dispatches the request and success action', async () => {
        const mockShowAlertPayload = {
          memberId,
          alertMessage: APPROVAL_SUCCESSFUL_MESSAGE,
          alertVariant: 'info',
        };

        await testAction({
          action: actions.approveMember,
          payload: memberId,
          state,
          expectedMutations: [
            { type: types.SET_MEMBER_AS_LOADING, payload: memberId },
            { type: types.SET_MEMBER_AS_APPROVED, payload: memberId },
            { type: types.SHOW_ALERT, payload: mockShowAlertPayload },
          ],
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock
          .onPut(`/api/v4/groups/1/members/${memberId}/approve`)
          .replyOnce(HTTP_STATUS_NOT_FOUND, {});
      });

      it('dispatches the request and error action', async () => {
        const mockShowAlertPayload = {
          memberId,
          alertMessage: APPROVAL_ERROR_MESSAGE,
          alertVariant: 'danger',
        };

        await testAction({
          action: actions.approveMember,
          payload: memberId,
          state,
          expectedMutations: [
            { type: types.SET_MEMBER_AS_LOADING, payload: memberId },
            { type: types.SET_MEMBER_ERROR, payload: memberId },
            { type: types.SHOW_ALERT, payload: mockShowAlertPayload },
          ],
        });
      });
    });
  });

  describe('approveAllMembers', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
      state.namespaceId = 1;
    });

    it('passes correct arguments to API call', () => {
      const spy = jest.spyOn(GroupsApi, 'approveAllPendingGroupMembers');

      testAction({
        action: actions.approveAllMembers,
        state,
        expectedMutations: expect.anything(),
        expectedActions: expect.anything(),
      });

      expect(spy).toHaveBeenCalledWith(state.namespaceId);
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onPost(`/api/v4/groups/1/members/approve_all`).replyOnce(HTTP_STATUS_NO_CONTENT);
      });

      it('dispatches the request and success action', async () => {
        const mockShowAlertPayload = {
          alertMessage: ALL_MEMBERS_APPROVAL_SUCCESSFUL_MESSAGE,
          alertVariant: 'info',
        };

        await testAction({
          action: actions.approveAllMembers,
          state,
          expectedMutations: [
            { type: types.SET_APPROVE_ALL_MEMBERS_AS_LOADING },
            { type: types.SET_APPROVE_ALL_MEMBERS_AS_DISABLED },
            { type: types.SET_ALL_MEMBERS_AS_APPROVED },
            { type: types.SHOW_ALERT, payload: mockShowAlertPayload },
            { type: types.SET_APPROVE_ALL_MEMBERS_AS_NOT_LOADING },
          ],
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPost(`/api/v4/groups/1/members/approve_all`).replyOnce(HTTP_STATUS_NOT_FOUND, {});
      });

      it('dispatches the request and error action', async () => {
        const mockShowAlertPayload = {
          alertMessage: ALL_MEMBERS_APPROVAL_ERROR_MESSAGE,
          alertVariant: 'danger',
        };

        await testAction({
          action: actions.approveAllMembers,
          state,
          expectedMutations: [
            { type: types.SET_APPROVE_ALL_MEMBERS_AS_LOADING },
            { type: types.SET_APPROVE_ALL_MEMBERS_AS_ENABLED },
            { type: types.SET_ALL_MEMBERS_ERROR },
            { type: types.SHOW_ALERT, payload: mockShowAlertPayload },
            { type: types.SET_APPROVE_ALL_MEMBERS_AS_NOT_LOADING },
          ],
        });
      });
    });
  });
});
