import { __ } from '~/locale';
import Api from 'ee/api';

/* eslint-disable @gitlab/require-i18n-strings */
const SYSTEM_MESSAGE = 'You are a sophisticated code review assistant.';
const PROMPT = [
  'You are creating an action list for the code author.',
  'You are provided with pairs of file path and a corresponding code comment.',
  'Filter these pairs to exclude any praise comments or anything unrelated to code review.',
  'Then use that to create a concise high level summary of the code review and present it as an action list for the reviewer in Markdown.',
  'DO NOT create any titles in the result.',
  'Provide a result in this format ONLY: "Here\'s a quick summary of the code review:\n<action list>"',
].join(' ');
/* eslint-enable @gitlab/require-i18n-strings */

export const createSummarizeMyReview = (store) => {
  return {
    title: __('Summarize my code review'),
    description: __('Creates a summary of all your draft code comments'),
    async handler() {
      const { drafts } = store.state.batchComments;
      if (!drafts.length) {
        throw new Error(__('Unable to summarize your review. No draft comments found.'));
      }
      const processedDrafts = drafts.map(
        (draft) => `File path: ${draft.file_path}\nComment: ${draft.note}`,
      );
      const content = `${PROMPT}\n\n${processedDrafts.join('\n\n')}`;
      const { data } = await Api.requestAIChat({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: SYSTEM_MESSAGE,
          },
          {
            role: 'user',
            content,
          },
        ],
        max_tokens: 100,
        temperature: 0.2,
        presence_penalty: 1,
      });
      return data.choices[0].message.content;
    },
  };
};
