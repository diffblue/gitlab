import { initRelatedFeatureFlags } from 'ee/issues';
import { store } from '~/notes/stores';
import initShow from '~/issues/show';
import initRelatedIssues from '~/related_issues';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import initUnableToLinkVulnerabilityError from 'ee/issues/init_unable_to_link_vulnerability_error';
import UserCallout from '~/user_callout';

initShow();
initSidebarBundle(store);
initRelatedIssues();
initRelatedFeatureFlags();
initUnableToLinkVulnerabilityError();

// eslint-disable-next-line no-new
new UserCallout({ className: 'js-epics-sidebar-callout' });
// eslint-disable-next-line no-new
new UserCallout({ className: 'js-weight-sidebar-callout' });
