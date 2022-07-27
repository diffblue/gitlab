import { initRelatedFeatureFlags, initUnableToLinkVulnerabilityError } from 'ee/issues';
import { initShow } from '~/issues';
import { store } from '~/notes/stores';
import { initRelatedIssues } from '~/related_issues';
import initWorkItemLinks from '~/work_items/components/work_item_links';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import UserCallout from '~/user_callout';

initShow();
initSidebarBundle(store);
initRelatedIssues();
initRelatedFeatureFlags();
initUnableToLinkVulnerabilityError();
initWorkItemLinks();

new UserCallout({ className: 'js-epics-sidebar-callout' }); // eslint-disable-line no-new
new UserCallout({ className: 'js-weight-sidebar-callout' }); // eslint-disable-line no-new
