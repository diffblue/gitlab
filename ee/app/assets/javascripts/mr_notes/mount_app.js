import initNotes from '~/mr_notes/init_notes';
import { createSummarizeMyReview } from 'ee/ai/editor_actions/summarize_my_review';
import store from '~/mr_notes/stores';

// this module is required for the EE functions to work properly with merge request tabs
export default () => {
  const editorAiActions = [];
  if (window.gon?.features?.summarizeMyCodeReview) {
    editorAiActions.push(createSummarizeMyReview(store));
  }
  initNotes({
    editorAiActions,
  });
};
