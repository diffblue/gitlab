import { initRelatedFeatureFlags, initUnableToLinkVulnerabilityError } from 'ee/issues';
import { initShow } from '~/issues';
import { store } from '~/notes/stores';
import { initRelatedIssues } from '~/related_issues';
import initWorkItemLinks from '~/work_items/components/work_item_links';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import UserCallout from '~/user_callout';
import { summarizeCommentsAction } from 'ee/notes/ai/summarize_comments';
import { convertToGraphQLId } from '~/graphql_shared/utils';

const editorAiActions = [];

if (window.gon?.features?.summarizeComments) {
  editorAiActions.push((noteableData) => {
    const resourceGlobalId = convertToGraphQLId(noteableData.noteableType, noteableData.id);
    return summarizeCommentsAction(resourceGlobalId);
  });
}

initShow({ notesParams: { editorAiActions } });
initSidebarBundle(store);
initRelatedIssues();
initRelatedFeatureFlags();
initUnableToLinkVulnerabilityError();
initWorkItemLinks();

new UserCallout({ className: 'js-epics-sidebar-callout' }); // eslint-disable-line no-new
new UserCallout({ className: 'js-weight-sidebar-callout' }); // eslint-disable-line no-new
