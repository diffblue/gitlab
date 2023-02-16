import '~/pages/projects/settings/merge_requests';
import mountApprovals from 'ee/approvals/mount_project_settings';
import { initMergeOptionSettings } from 'ee/pages/projects/edit/merge_options';
import { initMergeRequestMergeChecksApp } from 'ee/merge_checks';
import mountStatusChecks from 'ee/status_checks/mount';

mountApprovals(document.getElementById('js-mr-approvals-settings'));
mountStatusChecks(document.getElementById('js-status-checks-settings'));

initMergeOptionSettings();
initMergeRequestMergeChecksApp();
