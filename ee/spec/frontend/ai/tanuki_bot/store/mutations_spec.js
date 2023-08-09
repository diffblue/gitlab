import * as types from 'ee/ai/tanuki_bot/store/mutation_types';
import mutations from 'ee/ai/tanuki_bot/store/mutations';
import createState from 'ee/ai/tanuki_bot/store/state';
import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../mock_data';

describe('GitLab Duo Chat Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState();
  });

  describe('ADD_MESSAGE', () => {
    const requestId = '123';
    const userMessageWithRequestId = { ...MOCK_USER_MESSAGE, requestId };

    describe('tool message', () => {
      it.each(['tool_info', 'TOOL_INFO'])(
        'ignores the messages with role="%s" and does not populate the state',
        (role) => {
          const messageData = {
            ...MOCK_USER_MESSAGE,
            role,
          };
          mutations[types.ADD_MESSAGE](state, messageData);
          expect(state.messages).toStrictEqual([]);
        },
      );
    });

    describe('when there is no message with the same requestId', () => {
      it.each`
        messageData                                                                  | expectedState
        ${MOCK_USER_MESSAGE}                                                         | ${[MOCK_USER_MESSAGE]}
        ${{ content: 'foo', role: GENIE_CHAT_MODEL_ROLES.assistant }}                | ${[{ content: 'foo', role: GENIE_CHAT_MODEL_ROLES.assistant }]}
        ${{ content: 'foo', source: 'bar', role: GENIE_CHAT_MODEL_ROLES.assistant }} | ${[{ content: 'foo', source: 'bar', role: GENIE_CHAT_MODEL_ROLES.assistant }]}
        ${{}}                                                                        | ${[]}
        ${undefined}                                                                 | ${[]}
      `('pushes a message object to state', ({ messageData, expectedState }) => {
        mutations[types.ADD_MESSAGE](state, messageData);
        expect(state.messages).toStrictEqual(expectedState);
      });
    });

    describe('when there is a message with the same requestId', () => {
      describe('when the message is of the same role', () => {
        const updatedContent = 'Updated content';
        it('updates the message object if it is of exactly the same role', () => {
          state.messages.push({ ...MOCK_USER_MESSAGE, requestId });
          mutations[types.ADD_MESSAGE](state, {
            ...MOCK_USER_MESSAGE,
            requestId,
            content: updatedContent,
          });
          expect(state.messages.length).toBe(1);
          expect(state.messages).toStrictEqual([
            {
              ...MOCK_USER_MESSAGE,
              requestId,
              content: updatedContent,
            },
          ]);
        });
        it('still updates despite the captialization differences in the role', () => {
          state.messages.push({
            ...MOCK_USER_MESSAGE,
            requestId,
            role: MOCK_USER_MESSAGE.role.toLowerCase(),
          });
          mutations[types.ADD_MESSAGE](state, {
            requestId,
            role: MOCK_USER_MESSAGE.role.toUpperCase(),
            content: updatedContent,
          });
          expect(state.messages.length).toBe(1);
          expect(state.messages).toStrictEqual([
            {
              ...MOCK_USER_MESSAGE,
              requestId,
              role: MOCK_USER_MESSAGE.role.toUpperCase(),
              content: updatedContent,
            },
          ]);
        });
      });
      it('correctly injects a new ASSISTANT message right after the corresponding USER message', () => {
        const promptRequestId = '456';
        const userPrompt = {
          ...MOCK_USER_MESSAGE,
          requestId: promptRequestId,
        };
        const responseToPrompt = {
          ...MOCK_TANUKI_MESSAGE,
          requestId: promptRequestId,
        };
        state.messages.push(userPrompt, userMessageWithRequestId);

        mutations[types.ADD_MESSAGE](state, responseToPrompt);
        expect(state.messages.length).toBe(3);
        expect(state.messages).toStrictEqual([
          userPrompt,
          responseToPrompt,
          userMessageWithRequestId,
        ]);
      });
    });

    it.each`
      initState                                                                        | newMessageData                              | expectedLoadingState
      ${[]}                                                                            | ${MOCK_USER_MESSAGE}                        | ${true}
      ${[MOCK_USER_MESSAGE]}                                                           | ${{ ...MOCK_USER_MESSAGE, content: 'foo' }} | ${true}
      ${[{ ...MOCK_USER_MESSAGE, requestId }]}                                         | ${{ ...MOCK_USER_MESSAGE, requestId }}      | ${true}
      ${[{ ...MOCK_USER_MESSAGE, requestId }, MOCK_TANUKI_MESSAGE, MOCK_USER_MESSAGE]} | ${{ ...MOCK_TANUKI_MESSAGE, requestId }}    | ${true}
      ${[MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE, { ...MOCK_USER_MESSAGE, requestId }]} | ${{ ...MOCK_TANUKI_MESSAGE, requestId }}    | ${false}
      ${[{ ...MOCK_USER_MESSAGE, requestId }]}                                         | ${{ ...MOCK_TANUKI_MESSAGE, requestId }}    | ${false}
      ${[MOCK_USER_MESSAGE]}                                                           | ${MOCK_TANUKI_MESSAGE}                      | ${false}
    `(
      'correctly manages the loading state when initial state is "$initState" and new message is "$newMessageData"',
      ({ initState, newMessageData, expectedLoadingState }) => {
        state.loading = true;
        state.messages = initState;
        mutations[types.ADD_MESSAGE](state, newMessageData);
        expect(state.loading).toBe(expectedLoadingState);
      },
    );
  });

  describe('SET_LOADING', () => {
    it('sets loading to passed boolean', () => {
      mutations[types.SET_LOADING](state, true);

      expect(state.loading).toBe(true);
    });
  });

  describe('ADD_TOOL_MESSAGE', () => {
    const toolMessage = {
      ...MOCK_USER_MESSAGE,
      role: GENIE_CHAT_MODEL_ROLES.tool,
    };
    it.each`
      desc              | message              | isLoading | expectedState
      ${'sets'}         | ${toolMessage}       | ${true}   | ${toolMessage}
      ${'does not set'} | ${MOCK_USER_MESSAGE} | ${true}   | ${''}
      ${'does not set'} | ${toolMessage}       | ${false}  | ${''}
    `(
      '$desc the `toolMessage` when message is $message and loading is $isLoading',
      ({ message, isLoading, expectedState }) => {
        state.loading = isLoading;
        mutations[types.ADD_TOOL_MESSAGE](state, message);

        expect(state.toolMessage).toStrictEqual(expectedState);
      },
    );
  });
});
