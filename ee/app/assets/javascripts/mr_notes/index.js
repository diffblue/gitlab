import initMrNotes from '~/mr_notes/init_mr_notes';
import { createSummarizeMyReview } from 'ee/ai/editor_actions/summarize_my_review';
import store from '~/mr_notes/stores';

export default () => {
  const editorAiActions = [];
  if (window.gon?.features?.summarizeMyCodeReview) {
    editorAiActions.push(createSummarizeMyReview(store));
  }
  initMrNotes({
    reviewBarParams: {
      editorAiActions,
    },
  });
};
