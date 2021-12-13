import MockAdapter from 'axios-mock-adapter';
import State from 'ee/pending_members/store/state';
import * as GroupsApi from 'ee/api/groups_api';
import * as actions from 'ee/pending_members/store/actions';
import * as types from 'ee/pending_members/store/mutation_types';
import { mockDataMembers } from 'ee_jest/pending_members/mock_data';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

jest.mock('~/flash');

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

      expect(spy).toBeCalledWith(state.namespaceId, expect.objectContaining(payload));
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet('/api/v4/groups/1/pending_members')
          .replyOnce(httpStatusCodes.OK, mockDataMembers.data, mockDataMembers.headers);
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
        mock.onGet('/api/v4/groups/1/pending_members').replyOnce(httpStatusCodes.NOT_FOUND, {});
      });

      it('dispatches the request and error action', async () => {
        await testAction({
          action: actions.fetchPendingMembersList,
          state,
          expectedMutations: [
            { type: types.REQUEST_PENDING_MEMBERS },
            { type: types.RECEIVE_PENDING_MEMBERS_ERROR },
          ],
        });
        expect(createFlash).toHaveBeenCalled();
      });
    });
  });
});
