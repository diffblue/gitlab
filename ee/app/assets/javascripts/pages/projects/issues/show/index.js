import { initRelatedFeatureFlags, initUnableToLinkVulnerabilityError } from 'ee/issues';
import { initShow } from '~/issues';
import UserCallout from '~/user_callout';

initShow();
initRelatedFeatureFlags();
initUnableToLinkVulnerabilityError();

new UserCallout({ className: 'js-epics-sidebar-callout' }); // eslint-disable-line no-new
new UserCallout({ className: 'js-weight-sidebar-callout' }); // eslint-disable-line no-new
