import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/ai/tanuki_bot/store/actions';
import * as types from 'ee/ai/tanuki_bot/store/mutation_types';
import createState from 'ee/ai/tanuki_bot/store/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../mock_data';

describe('TanukiBot Store Actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = createState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  describe('sendMessage', () => {
    describe('onSuccess', () => {
      beforeEach(() => {
        mock.onPost().reply(HTTP_STATUS_OK, MOCK_TANUKI_MESSAGE);
      });

      it(`should dispatch the correct mutations`, () => {
        return testAction({
          action: actions.sendMessage,
          payload: MOCK_USER_MESSAGE.msg,
          state,
          expectedMutations: [
            { type: types.SET_LOADING, payload: true },
            { type: types.ADD_USER_MESSAGE, payload: MOCK_USER_MESSAGE.msg },
            { type: types.ADD_TANUKI_MESSAGE, payload: MOCK_TANUKI_MESSAGE },
            { type: types.SET_LOADING, payload: false },
          ],
        });
      });
    });

    describe('onError', () => {
      beforeEach(() => {
        mock.onPost().reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it(`should dispatch the correct mutations`, () => {
        return testAction({
          action: actions.sendMessage,
          payload: MOCK_USER_MESSAGE.msg,
          state,
          expectedMutations: [
            { type: types.SET_LOADING, payload: true },
            { type: types.ADD_USER_MESSAGE, payload: MOCK_USER_MESSAGE.msg },
            { type: types.ADD_ERROR_MESSAGE },
            { type: types.SET_LOADING, payload: false },
          ],
        });
      });
    });
  });
});
