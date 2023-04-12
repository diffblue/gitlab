import { s__, __, sprintf } from '~/locale';
import Api from 'ee/api';

const MAX_TOKENS = 300;
const TEMPERATURE = 0.3;
const askGenie = async (content) => {
  const {
    data: { choices },
  } = await Api.requestAIChat({
    model: 'gpt-3.5-turbo',
    max_tokens: MAX_TOKENS,
    temperature: TEMPERATURE,
    messages: [
      {
        role: 'system',
        content: 'You are a knowledgeable assistant explaining to an engineer', // eslint-disable-line
      },
      {
        role: 'user',
        content,
      },
    ],
  }).catch((error) => {
    throw new Error(error.response.data.error.message);
  });

  return choices[0];
};

export const explainCode = (text, filePath) => {
  const prompt = sprintf(
    s__(
      'AI|Explain the code from %{filePath} in human understandable language presented in Markdown format. In the response add neither original code snippet nor any title. `%{text}`',
    ),
    {
      filePath: filePath || __('random'),
      text,
    },
  );
  return askGenie(prompt);
};
