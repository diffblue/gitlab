import { s__, __, sprintf } from '~/locale';

export const explainCodePrompt = s__(
  'AI|Explain the code from %{filePath} in human understandable language presented in Markdown format. In the response add neither original code snippet nor any title. `%{text}`',
);

export const generatePrompt = (text, filePath) => {
  const content = sprintf(explainCodePrompt, {
    filePath: filePath || __('random'),
    text,
  });

  return [
    {
      role: 'system',
      content: 'You are a knowledgeable assistant explaining to an engineer', // eslint-disable-line
    },
    { role: 'user', content },
  ];
};
