import { utils } from 'ee/ai/utils';
import {
  i18n,
  TOKENS_THRESHOLD,
  MAX_RESPONSE_TOKENS,
  GENIE_CHAT_MODEL_ROLES,
} from 'ee/ai/constants';
import { sprintf } from '~/locale';

jest.mock('ee/ai/constants', () => {
  // To simplify the things in testing, we override the constatants
  // to make the MAX_RESPONSE_TOKENS and TOKENS_THRESHOLD smaller
  // and easier to control
  const originalConstants = jest.requireActual('ee/ai/constants');
  return {
    ...originalConstants,
    TOKENS_THRESHOLD: 40, // 36 * 4 = 144 characters.
    MAX_RESPONSE_TOKENS: 4, // 4 * 4 = 16 characters.
  };
});

const MAX_PROMPT_TOKENS = TOKENS_THRESHOLD - MAX_RESPONSE_TOKENS; // 36 tokens

describe('AI Utils', () => {
  describe('generateExplainCodePrompt', () => {
    const filePath = 'fooPath';
    const fileText = 'barText';

    it('generates a prompts based of the file path and text', () => {
      const result = utils.generateExplainCodePrompt(fileText, filePath);
      const content = sprintf(i18n.EXPLAIN_CODE_PROMPT, {
        filePath,
        text: fileText,
      });
      expect(result).toEqual(content);
    });
  });

  describe('generateChatPrompt', () => {
    describe('when the prompt is not too large', () => {
      const userPrompt = 'U';
      const userMessage = {
        role: GENIE_CHAT_MODEL_ROLES.user,
        content: userPrompt,
      };
      const defaultPrompt = [
        {
          role: GENIE_CHAT_MODEL_ROLES.system,
          content: 'You are an assistant explaining to an engineer',
        },
        userMessage,
      ];

      it.each`
        desc                                                                                                           | newPrompt     | basePrompts      | expectedPrompts
        ${'returns [] for "newPrompt = undefined" and "basePrompts = []"'}                                             | ${undefined}  | ${[]}            | ${[]}
        ${'returns [] for `newPrompt = ""` and "basePrompts = []"'}                                                    | ${''}         | ${[]}            | ${[]}
        ${'returns defaultPrompt for "newPrompt = undefined" and "basePrompts = defaultPrompt"'}                       | ${undefined}  | ${defaultPrompt} | ${defaultPrompt}
        ${'returns defaultPrompt for `newPrompt = ""` and "basePrompts = defaultPrompt"'}                              | ${''}         | ${defaultPrompt} | ${defaultPrompt}
        ${'returns defaultPrompt for `newPrompt = userPrompt` and "basePrompts = []"'}                                 | ${userPrompt} | ${[]}            | ${defaultPrompt}
        ${'returns { ...defaultPrompt, userMessage }  for `newPrompt = userPrompt` and "basePrompts = defaultPrompt"'} | ${userPrompt} | ${defaultPrompt} | ${[...defaultPrompt, userMessage]}
      `('$desc', ({ newPrompt, basePrompts, expectedPrompts }) => {
        expect(utils.generateChatPrompt(newPrompt, basePrompts)).toEqual(expectedPrompts);
      });
    });

    describe('when the prompt is too large', () => {
      let result;
      let computeTokensSpy;
      const systemMessage = {
        role: GENIE_CHAT_MODEL_ROLES.system,
        content: 'alpha',
      };
      const userMessage1 = {
        role: GENIE_CHAT_MODEL_ROLES.user,
        content: 'beta1',
      };
      const userMessage2 = {
        role: GENIE_CHAT_MODEL_ROLES.user,
        content: 'beta2',
      };
      const assistantMessage1 = {
        role: GENIE_CHAT_MODEL_ROLES.assistant,
        content: 'gamma1',
      };
      const assistantMessage2 = {
        role: GENIE_CHAT_MODEL_ROLES.assistant,
        content: 'gamma2',
      };
      const basePrompts = [
        systemMessage,
        userMessage1,
        assistantMessage1,
        userMessage2,
        assistantMessage2,
      ];
      const userPrompt = 'delta';
      const lastUserMessage = {
        role: GENIE_CHAT_MODEL_ROLES.user,
        content: userPrompt,
      };

      afterEach(() => {
        result = null;
        computeTokensSpy.mockRestore();
      });

      it('first, drops the system message if the prompt tokens length is at or exceeds the threshold MAX_PROMPT_TOKENS', () => {
        computeTokensSpy = jest
          .spyOn(utils, 'computeTokens')
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementation(() => MAX_PROMPT_TOKENS - 1);
        result = utils.generateChatPrompt(userPrompt, basePrompts);
        expect(result).toEqual([
          userMessage1,
          assistantMessage1,
          userMessage2,
          assistantMessage2,
          lastUserMessage,
        ]);
      });

      it('then drops the user messages if the prompt tokens length is still at or exceeds the threshold MAX_PROMPT_TOKENS', () => {
        computeTokensSpy = jest
          .spyOn(utils, 'computeTokens')
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementation(() => MAX_PROMPT_TOKENS - 1);
        result = utils.generateChatPrompt(userPrompt, basePrompts);
        expect(result).toEqual([assistantMessage1, assistantMessage2, lastUserMessage]);
      });

      it('then drops the assistant messages if the prompt tokens length is still at or exceeds the threshold MAX_PROMPT_TOKENS', () => {
        computeTokensSpy = jest
          .spyOn(utils, 'computeTokens')
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementation(() => MAX_PROMPT_TOKENS - 1);
        result = utils.generateChatPrompt(userPrompt, basePrompts);
        expect(result).toEqual([assistantMessage2, lastUserMessage]);
      });

      it('throws an error if there are only two messages and the prompt is still too large and can not be truncated', () => {
        computeTokensSpy = jest
          .spyOn(utils, 'computeTokens')
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementationOnce(() => MAX_PROMPT_TOKENS)
          .mockImplementation(() => MAX_PROMPT_TOKENS - 1);
        expect(() => utils.generateChatPrompt(userPrompt, basePrompts)).toThrow(
          i18n.TOO_LONG_ERROR_MESSAGE,
        );
      });
    });
  });

  describe('computeTokens', () => {
    it.each`
      messagesDesc                                                                   | messages                                                                                                               | expectedTokens
      ${"[{ role: '', content: '' }]"}                                               | ${[{ role: '', content: '' }]}                                                                                         | ${Math.ceil(0 + 4 + 3)}
      ${"[{ role: 'system', content: '' }]"}                                         | ${[{ role: GENIE_CHAT_MODEL_ROLES.system, content: '' }]}                                                              | ${Math.ceil('system'.length / 4 + 4 + 3)}
      ${"[{ role: 'user', content: 'foo' }]"}                                        | ${[{ role: GENIE_CHAT_MODEL_ROLES.user, content: 'foo' }]}                                                             | ${Math.ceil('userfoo'.length / 4 + 4 + 3)}
      ${"[{ role: 'user', content: 'foo' }, { role: 'assistant', content: 'bar' }]"} | ${[{ role: GENIE_CHAT_MODEL_ROLES.user, content: 'foo' }, { role: GENIE_CHAT_MODEL_ROLES.assistant, content: 'bar' }]} | ${Math.ceil('userfooassistantbar'.length / 4 + 4 * 2 + 3)}
    `(
      'correctly computes the number of tokens for $messagesDesc',
      ({ messages, expectedTokens }) => {
        expect(utils.computeTokens(messages)).toBe(expectedTokens);
      },
    );
  });
});
