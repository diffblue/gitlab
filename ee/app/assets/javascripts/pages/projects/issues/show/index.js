import initRelatedFeatureFlags from 'ee/related_feature_flags';
import { store } from '~/notes/stores';
import initShow from '~/pages/projects/issues/show';
import initRelatedIssues from '~/related_issues';
import initSidebarBundle from '~/sidebar/sidebar_bundle';
import UserCallout from '~/user_callout';

initShow();
initSidebarBundle(store);
initRelatedIssues();
initRelatedFeatureFlags();

// eslint-disable-next-line no-new
new UserCallout({ className: 'js-epics-sidebar-callout' });
// eslint-disable-next-line no-new
new UserCallout({ className: 'js-weight-sidebar-callout' });
