import * as actions from 'ee/ai/tanuki_bot/store/actions';
import * as types from 'ee/ai/tanuki_bot/store/mutation_types';
import createState from 'ee/ai/tanuki_bot/store/state';
import testAction from 'helpers/vuex_action_helper';
import {
  MOCK_USER_MESSAGE,
  MOCK_TANUKI_MESSAGE,
  MOCK_TANUKI_SUCCESS_RES,
  MOCK_TANUKI_ERROR_RES,
} from '../mock_data';

describe('TanukiBot Store Actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  afterEach(() => {
    state = null;
  });

  describe('sendUserMessage', () => {
    it(`should dispatch the correct mutations`, () => {
      return testAction({
        action: actions.sendUserMessage,
        payload: MOCK_USER_MESSAGE.msg,
        state,
        expectedMutations: [
          { type: types.SET_LOADING, payload: true },
          { type: types.ADD_USER_MESSAGE, payload: MOCK_USER_MESSAGE.msg },
        ],
      });
    });
  });

  describe('receiveTanukiBotMessage', () => {
    describe('with response', () => {
      it(`should dispatch the correct mutations`, () => {
        return testAction({
          action: actions.receiveTanukiBotMessage,
          payload: MOCK_TANUKI_SUCCESS_RES.data,
          state,
          expectedMutations: [
            { type: types.SET_LOADING, payload: false },
            { type: types.ADD_TANUKI_MESSAGE, payload: MOCK_TANUKI_MESSAGE },
          ],
        });
      });
    });

    describe('with error', () => {
      it(`should dispatch the correct actions`, () => {
        return testAction({
          action: actions.receiveTanukiBotMessage,
          payload: MOCK_TANUKI_ERROR_RES.data,
          state,
          expectedActions: [{ type: 'tanukiBotMessageError' }],
        });
      });
    });
  });

  describe('tanukiBotMessageError', () => {
    it(`should dispatch the correct mutations`, () => {
      return testAction({
        action: actions.tanukiBotMessageError,
        state,
        expectedMutations: [
          { type: types.SET_LOADING, payload: false },
          { type: types.ADD_ERROR_MESSAGE },
        ],
      });
    });
  });

  describe('setMessages', () => {
    it('should dispatch the correct mutations', () => {
      return testAction({
        action: actions.setMessages,
        payload: [MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE],
        state,
        expectedMutations: [
          { type: types.SET_LOADING, payload: false },
          { type: types.ADD_USER_MESSAGE, payload: MOCK_USER_MESSAGE.content },
          { type: types.ADD_TANUKI_MESSAGE, payload: MOCK_TANUKI_MESSAGE },
        ],
      });
    });
    it('does not set loading to false if the last messages is from a user', () => {
      return testAction({
        action: actions.setMessages,
        payload: [MOCK_TANUKI_MESSAGE, MOCK_USER_MESSAGE],
        state,
        expectedMutations: [
          { type: types.ADD_TANUKI_MESSAGE, payload: MOCK_TANUKI_MESSAGE },
          { type: types.ADD_USER_MESSAGE, payload: MOCK_USER_MESSAGE.content },
        ],
      });
    });
    it('does correctly parse messages content if it is a JSON object', () => {
      const contentObject = {
        content: MOCK_TANUKI_MESSAGE.content,
        source: 'foo-bar',
      };
      const stringifiedContent = JSON.stringify(contentObject);
      return testAction({
        action: actions.setMessages,
        payload: [
          MOCK_USER_MESSAGE,
          {
            ...MOCK_TANUKI_MESSAGE,
            content: stringifiedContent,
          },
        ],
        state,
        expectedMutations: [
          { type: types.SET_LOADING, payload: false },
          { type: types.ADD_USER_MESSAGE, payload: MOCK_USER_MESSAGE.content },
          { type: types.ADD_TANUKI_MESSAGE, payload: contentObject },
        ],
      });
    });
    it('if messge has an error, it correctly commits the ADD_ERROR_MESSAGE nmutation', () => {
      return testAction({
        action: actions.setMessages,
        payload: [
          {
            ...MOCK_USER_MESSAGE,
            errors: ['foo'],
          },
          {
            ...MOCK_TANUKI_MESSAGE,
            errors: ['foo'],
          },
        ],
        state,
        expectedMutations: [
          { type: types.SET_LOADING, payload: false },
          { type: types.ADD_ERROR_MESSAGE },
          { type: types.ADD_ERROR_MESSAGE },
        ],
      });
    });
  });
});
