/* eslint-disable no-new */

import '~/pages/projects/edit';
import { initServicePingSettingsClickTracking } from 'ee/registration_features_discovery_message';
import initProjectAdjournedDeleteButton from 'ee/projects/project_adjourned_delete_button';
import initProjectComplianceFrameworkEmptyState from 'ee/projects/project_compliance_framework_empty_state';
import groupsSelect from '~/groups_select';
import UserCallout from '~/user_callout';

groupsSelect();

new UserCallout({ className: 'js-mr-approval-callout' });

initProjectAdjournedDeleteButton();
initProjectComplianceFrameworkEmptyState();
initServicePingSettingsClickTracking();
