/* eslint-disable no-new */

import '~/pages/projects/edit';
import { initServicePingSettingsClickTracking } from 'ee/registration_features_discovery_message';
import initProjectDelayedDeleteButton from 'ee/projects/project_delayed_delete_button';
import initProjectComplianceFrameworkEmptyState from 'ee/projects/project_compliance_framework_empty_state';
import groupsSelect from '~/groups_select';
import UserCallout from '~/user_callout';

groupsSelect();

new UserCallout({ className: 'js-mr-approval-callout' });

initProjectDelayedDeleteButton();
initProjectComplianceFrameworkEmptyState();
initServicePingSettingsClickTracking();
