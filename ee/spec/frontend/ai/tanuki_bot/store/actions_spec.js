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

    it('does correctly parse messages content if it is a JSON object', () => {
      const contentObject = {
        content: MOCK_TANUKI_MESSAGE.content,
        source: 'foo-bar',
      };
      const stringifiedContent = JSON.stringify(contentObject);
      return testAction({
        action: actions.receiveTanukiBotMessage,
        payload: GENERATE_MOCK_TANUKI_RES(stringifiedContent).data,
        state,
        expectedMutations: [
          { type: types.SET_LOADING, payload: false },
          { type: types.ADD_TANUKI_MESSAGE, payload: contentObject },
        ],
      });
    });

    describe('with error', () => {
      it(`should dispatch the correct actions`, () => {
        const contentObject = {
          content: '',
          source: 'foo-bar',
        };
        const stringifiedContent = JSON.stringify(contentObject);
        return testAction({
          action: actions.receiveTanukiBotMessage,
          payload: MOCK_TANUKI_ERROR_RES(stringifiedContent).data,
          state,
          expectedActions: [
            {
              payload: contentObject,
              type: 'tanukiBotMessageError',
            },
          ],
        });
      });
    });
  });

  describe('receiveMutationResponse', () => {
    it('on success it should commit the correct mutation', () => {
      return testAction({
        action: actions.receiveMutationResponse,
        payload: { data: { aiAction: { errors: [] } }, message: GENIE_CHAT_RESET_MESSAGE },
        state,
        expectedMutations: [{ type: types.SET_LOADING, payload: false }],
      });
    });

    it('on error it should dispatch the error action', () => {
      return testAction({
        action: actions.receiveMutationResponse,
        payload: {
          data: { aiAction: { errors: ['some error'] } },
          message: GENIE_CHAT_RESET_MESSAGE,
        },
        state,
        expectedActions: [{ type: 'tanukiBotMessageError' }],
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
    it('should dispatch the correct actions', () => {
      return testAction({
        action: actions.setMessages,
        payload: [MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE],
        state,
        expectedActions: [
          { type: 'sendUserMessage', payload: MOCK_USER_MESSAGE.content },
          {
            type: 'receiveTanukiBotMessage',
            payload: { aiCompletionResponse: { responseBody: MOCK_TANUKI_MESSAGE.content } },
          },
        ],
        expectedMutations: [{ type: types.SET_LOADING, payload: false }],
      });
    });
    it('sets loading to false even if the last message is from user', () => {
      return testAction({
        action: actions.setMessages,
        payload: [MOCK_TANUKI_MESSAGE, MOCK_USER_MESSAGE],
        state,
        expectedActions: [
          {
            type: 'receiveTanukiBotMessage',
            payload: { aiCompletionResponse: { responseBody: MOCK_TANUKI_MESSAGE.content } },
          },
          { type: 'sendUserMessage', payload: MOCK_USER_MESSAGE.content },
        ],
        expectedMutations: [{ type: types.SET_LOADING, payload: false }],
      });
    });
    it('if messge has an error, it correctly dispatches the tanukiBotMessageError action', () => {
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
        expectedActions: [
          {
            type: 'tanukiBotMessageError',
            payload: {
              ...MOCK_USER_MESSAGE,
              errors: ['foo'],
            },
          },
          {
            type: 'tanukiBotMessageError',
            payload: {
              ...MOCK_TANUKI_MESSAGE,
              errors: ['foo'],
            },
          },
        ],
      });
    });
  });
});
