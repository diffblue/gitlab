import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { fetchProtectedEnvironments } from 'ee/protected_environments/store/edit/actions';
import * as types from 'ee/protected_environments/store/edit/mutation_types';
import { state } from 'ee/protected_environments/store/edit/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

describe('ee/protected_environments/store/edit/actions', () => {
  let mockedState;
  let mock;
  let originalGon;

  beforeEach(() => {
    mockedState = state({ projectId: '8' });
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    mock.restore();
    mock.resetHistory();
    window.gon = originalGon;
  });

  describe('fetchProtectedEnvironments', () => {
    it('successfully calls the protected environments API and saves the result', () => {
      const environments = [{ name: 'staging' }];
      mock.onGet().replyOnce(HTTP_STATUS_OK, environments);
      return testAction(fetchProtectedEnvironments, undefined, mockedState, [
        { type: types.REQUEST_PROTECTED_ENVIRONMENTS },
        { type: types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS, payload: environments },
      ]);
    });

    it('saves the error on failure', () => {
      mock.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      return testAction(
        fetchProtectedEnvironments,
        undefined,
        mockedState,
        [
          { type: types.REQUEST_PROTECTED_ENVIRONMENTS },
          { type: types.RECEIVE_PROTECTED_ENVIRONMENTS_ERROR, payload: expect.any(Error) },
        ],
        [],
      );
    });
  });
});
