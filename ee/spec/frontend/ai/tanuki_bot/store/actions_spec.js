import * as actions from 'ee/ai/tanuki_bot/store/actions';
import * as types from 'ee/ai/tanuki_bot/store/mutation_types';
import createState from 'ee/ai/tanuki_bot/store/state';
import testAction from 'helpers/vuex_action_helper';
import { GENIE_CHAT_RESET_MESSAGE } from 'ee/ai/constants';
import {
  MOCK_USER_MESSAGE,
  MOCK_TANUKI_MESSAGE,
  MOCK_TANUKI_ERROR_RES,
  GENERATE_MOCK_TANUKI_RES,
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
      const documentationResponse = {
        content: 'Documentation foo',
        sources: { foo: 'bar' },
      };

      it.each`
        responseBody                             | expectedPayload
        ${'foo'}                                 | ${{ content: 'foo' }}
        ${JSON.stringify(documentationResponse)} | ${documentationResponse}
      `(
        'should dispatch the correct mutations for "$responseBody" response',
        ({ responseBody, expectedPayload }) => {
          return testAction({
            action: actions.receiveTanukiBotMessage,
            payload: GENERATE_MOCK_TANUKI_RES(responseBody).data,
            state,
            expectedMutations: [
              { type: types.SET_LOADING, payload: false },
              { type: types.ADD_TANUKI_MESSAGE, payload: expectedPayload },
            ],
          });
        },
      );
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

  describe('receiveMutationResponse', () => {
    it('on success it should dispatch the correct mutations', () => {
      return testAction({
        action: actions.receiveMutationResponse,
        payload: { data: { aiAction: { errors: [] } }, message: GENIE_CHAT_RESET_MESSAGE },
        state,
        expectedMutations: [{ type: types.SET_LOADING, payload: false }],
      });
    });

    it('on error it should dispatch the correct mutations', () => {
      return testAction({
        action: actions.receiveMutationResponse,
        payload: {
          data: { aiAction: { errors: ['some error'] } },
          message: GENIE_CHAT_RESET_MESSAGE,
        },
        state,
        expectedMutations: [
          { type: types.SET_LOADING, payload: false },
          { type: types.ADD_ERROR_MESSAGE },
        ],
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
