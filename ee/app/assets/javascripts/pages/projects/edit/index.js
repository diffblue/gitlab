/* eslint-disable no-new */

import '~/pages/projects/edit';
import { initServicePingSettingsClickTracking } from 'ee/registration_features_discovery_message';
import initProjectDelayedDeleteButton from 'ee/projects/project_delayed_delete_button';
import initProjectComplianceFrameworkEmptyState from 'ee/projects/project_compliance_framework_empty_state';
import UserCallout from '~/user_callout';

new UserCallout({ className: 'js-mr-approval-callout' });

initProjectDelayedDeleteButton();
initProjectComplianceFrameworkEmptyState();
initServicePingSettingsClickTracking();
