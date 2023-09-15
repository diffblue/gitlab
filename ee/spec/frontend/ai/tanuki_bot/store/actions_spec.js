import * as actions from 'ee/ai/tanuki_bot/store/actions';
import * as types from 'ee/ai/tanuki_bot/store/mutation_types';
import createState from 'ee/ai/tanuki_bot/store/state';
import testAction from 'helpers/vuex_action_helper';
import { GENIE_CHAT_MODEL_ROLES, CHAT_MESSAGE_TYPES } from 'ee/ai/constants';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../mock_data';

describe('TanukiBot Store Actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  afterEach(() => {
    state = null;
  });

  describe('addDuoChatMessage', () => {
    describe('with content', () => {
      const content = 'AI foo';
      const extras = { sources: [{ foo: 'bar' }] };

      const aiContentResponse = {
        content,
      };
      const documentationResponse = {
        content,
        extras,
      };

      it.each`
        messageData                                                         | expectedPayload
        ${aiContentResponse}                                                | ${{ content, role: GENIE_CHAT_MODEL_ROLES.user }}
        ${{ ...aiContentResponse, role: GENIE_CHAT_MODEL_ROLES.assistant }} | ${{ content, role: GENIE_CHAT_MODEL_ROLES.assistant }}
        ${documentationResponse}                                            | ${{ content, extras, role: GENIE_CHAT_MODEL_ROLES.user }}
      `(
        'should commit the correct mutations for "$messageData" response',
        ({ messageData, expectedPayload }) => {
          return testAction({
            action: actions.addDuoChatMessage,
            payload: messageData,
            state,
            expectedMutations: [{ type: types.ADD_MESSAGE, payload: expectedPayload }],
          });
        },
      );

      it('should not commit ADD_MESSAGE mutation for a response with empty content', () => {
        return testAction({
          action: actions.addDuoChatMessage,
          payload: { content: '' },
          state,
          expectedMutations: [],
        });
      });
    });

    describe('with error', () => {
      const justError = {
        errors: ['foo'],
      };
      const multipleErrors = {
        errors: ['foo', 'bar'],
      };
      const contentWithError = {
        content: 'content',
        source: 'foo-bar',
        errors: ['foo'],
      };
      const emptyContentWithError = {
        content: '',
        source: 'foo-bar',
        errors: ['foo'],
      };
      it.each`
        messageData              | expectedPayload
        ${justError}             | ${'foo'}
        ${multipleErrors}        | ${'foo; bar'}
        ${contentWithError}      | ${'content'}
        ${emptyContentWithError} | ${'foo'}
      `(
        'should commit the correct mutation for "$messageData"',
        ({ messageData, expectedPayload }) => {
          return testAction({
            action: actions.addDuoChatMessage,
            payload: messageData,
            state,
            expectedMutations: [
              {
                type: types.ADD_MESSAGE,
                payload: expect.objectContaining({ content: expectedPayload }),
              },
            ],
          });
        },
      );
    });

    describe('with incoming tool message', () => {
      it('commits the correct mutation', () => {
        const payload = {
          ...MOCK_USER_MESSAGE,
          role: GENIE_CHAT_MODEL_ROLES.system,
          type: CHAT_MESSAGE_TYPES.tool,
        };
        return testAction({
          action: actions.addDuoChatMessage,
          payload,
          state,
          expectedMutations: [{ type: types.ADD_TOOL_MESSAGE, payload }],
        });
      });
    });
  });

  describe('setMessages', () => {
    it('should dispatch the `addDuoChatMessage` action for every message', () => {
      return testAction({
        action: actions.setMessages,
        payload: [MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE],
        state,
        expectedActions: [
          { type: 'addDuoChatMessage', payload: MOCK_USER_MESSAGE },
          { type: 'addDuoChatMessage', payload: MOCK_TANUKI_MESSAGE },
        ],
      });
    });
  });

  describe('setLoading', () => {
    it.each([true, false])('should commit the correct mutation for "%s" flag', (flag) => {
      return testAction({
        action: actions.setLoading,
        payload: flag,
        state,
        expectedMutations: [{ type: types.SET_LOADING, payload: flag }],
      });
    });
  });
});
