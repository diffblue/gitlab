/* eslint-disable no-new */

import '~/pages/projects/edit';
import mountApprovals from 'ee/approvals/mount_project_settings';
import { initMergeOptionSettings } from 'ee/pages/projects/edit/merge_options';
import { initServicePingSettingsClickTracking } from 'ee/registration_features_discovery_message';
import initProjectAdjournedDeleteButton from 'ee/projects/project_adjourned_delete_button';
import mountStatusChecks from 'ee/status_checks/mount';
import groupsSelect from '~/groups_select';
import UserCallout from '~/user_callout';
import UsersSelect from '~/users_select';

new UsersSelect();
groupsSelect();

new UserCallout({ className: 'js-mr-approval-callout' });

mountApprovals(document.getElementById('js-mr-approvals-settings'));
mountStatusChecks(document.getElementById('js-status-checks-settings'));

initProjectAdjournedDeleteButton();
initMergeOptionSettings();
initServicePingSettingsClickTracking();
