import { findLastIndex } from 'lodash';
import { sprintf, __ } from '~/locale';
import { TOO_LONG_ERROR_TYPE, i18n, GENIE_CHAT_MODEL_ROLES } from './constants';

const areMessagesWithinLimit = (messages) => {
  const MAX_RESPONSE_TOKENS = gon.ai?.chat?.max_response_token;
  const TOKENS_THRESHOLD = gon.ai?.chat?.input_content_limit;

  if (!MAX_RESPONSE_TOKENS || !TOKENS_THRESHOLD) return true; // delegate dealing with the prompt size to BE

  // we use `utils.computeTokens()` below to make it easier to test and mock calls to computeTokens()
  // eslint-disable-next-line no-use-before-define
  return utils.computeTokens(messages) + MAX_RESPONSE_TOKENS < TOKENS_THRESHOLD;
};

/* eslint-disable consistent-return */
const truncateChatPrompt = (messages) => {
  if (areMessagesWithinLimit(messages)) {
    return messages;
  }

  // First, we get rid of the `system` prompt, because its value for the further conversation is not that important anymore
  const systemPromptIndex = messages.at(0).role === GENIE_CHAT_MODEL_ROLES.system ? 0 : -1;
  if (systemPromptIndex >= 0) {
    messages.splice(systemPromptIndex, 1);
    return truncateChatPrompt(messages);
  }

  // Here we do not want to truncate the last user prompt, because it is the one we need to respond to
  const lastUserPromptIndex = findLastIndex(
    messages,
    ({ role }) => role === GENIE_CHAT_MODEL_ROLES.user,
  );
  const firstUserPromptIndex = messages.findIndex(
    ({ role }) => role === GENIE_CHAT_MODEL_ROLES.user,
  );
  if (firstUserPromptIndex >= 0 && lastUserPromptIndex > firstUserPromptIndex) {
    messages.splice(firstUserPromptIndex, 1);
    return truncateChatPrompt(messages);
  }

  // Here we do not want to truncate the last assistant prompt, because this is the last context message we have to correctly answer the user prompt
  const lastAssistantPromptIndex = findLastIndex(
    messages,
    ({ role }) => role === GENIE_CHAT_MODEL_ROLES.assistant,
  );
  const firstAssistantPromptIndex = messages.findIndex(
    ({ role }) => role === GENIE_CHAT_MODEL_ROLES.assistant,
  );
  if (firstAssistantPromptIndex >= 0 && lastAssistantPromptIndex > firstAssistantPromptIndex) {
    messages.splice(firstAssistantPromptIndex, 1);
    return truncateChatPrompt(messages);
  }
  if (messages.length <= 2) {
    // By here, we could conclude that there's only one pair of assistant + user messages left and it still is too big to be sent
    // In this case, we should start splitting the message into smaller chunks and send them one by one, using the mapReduce strategy
    // This is not implemented yet, hence we throw an error
    throw new Error(i18n.TOO_LONG_ERROR_MESSAGE, {
      cause: TOO_LONG_ERROR_TYPE,
    });
  }
};
/* eslint-enable consistent-return */

const prepareChatPrompt = (newPrompt, messages, strategy) => {
  const doesContainSystemMessage = messages?.at(0)?.role === GENIE_CHAT_MODEL_ROLES.system;
  if (!doesContainSystemMessage) {
    messages.unshift({
      role: GENIE_CHAT_MODEL_ROLES.system,
      content: 'You are an assistant explaining to an engineer', // eslint-disable-line
    });
  }
  messages.push({ role: GENIE_CHAT_MODEL_ROLES.user, content: newPrompt });
  switch (strategy) {
    case 'truncate':
      return truncateChatPrompt(messages);
    default:
      return messages;
  }
};

export const generateChatPrompt = (newPrompt, messages) => {
  if (!newPrompt) return messages;
  const initMessages = messages.slice();
  return prepareChatPrompt(newPrompt, initMessages, 'truncate');
};

export const generateExplainCodePrompt = (text, filePath) => {
  return sprintf(i18n.EXPLAIN_CODE_PROMPT, {
    filePath: filePath || __('random'),
    text,
  });
};

export const computeTokens = (messages) => {
  // See https://github.com/openai/openai-cookbook/blob/main/examples/How_to_count_tokens_with_tiktoken.ipynb for more details
  const tokensPerMessage = 4; // every message follows <|start|>{role}\n{content}<|end|>\n

  let numTokens = 0;
  for (const message of messages) {
    numTokens += tokensPerMessage;
    for (const value of Object.values(message)) {
      numTokens += value.length / 4; // 4 bytes per token on average as per https://platform.openai.com/tokenizer
    }
  }
  numTokens += 3; // every reply is primed with <|start|>assistant<|message|>
  return Math.ceil(numTokens);
};

export const utils = {
  generateChatPrompt,
  generateExplainCodePrompt,
  computeTokens,
};
