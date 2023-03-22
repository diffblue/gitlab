/* eslint-disable no-new */
import 'bootstrap/js/dist/collapse';
import ProtectedBranchEditList from 'ee/protected_branches/protected_branch_edit_list';
import initDatePicker from '~/behaviors/date_picker';
import initDeployKeys from '~/deploy_keys';
import fileUpload from '~/lib/utils/file_upload';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';
import CEProtectedBranchEditList from '~/protected_branches/protected_branch_edit_list';
import ProtectedTagCreate from '~/protected_tags/protected_tag_create';
import ProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';
import UserCallout from '~/user_callout';
import mountBranchRules from '~/projects/settings/repository/branch_rules/mount_branch_rules';
import mountDefaultBranchSelector from '~/projects/settings/mount_default_branch_selector';
import EEMirrorRepos from './ee_mirror_repos';

new UserCallout();

initDeployKeys();
initSettingsPanels();

if (document.querySelector('.js-protected-refs-for-users')) {
  new ProtectedBranchCreate({ hasLicense: true });
  new ProtectedBranchEditList();

  new ProtectedTagCreate({ hasLicense: true });
  new ProtectedTagEditList({ hasLicense: true });
} else {
  new ProtectedBranchCreate({ hasLicense: false });
  new CEProtectedBranchEditList();
  new ProtectedTagCreate({ hasLicense: false });
  new ProtectedTagEditList({ hasLicense: false });
}

const pushPullContainer = document.querySelector('.js-mirror-settings');
if (pushPullContainer) new EEMirrorRepos(pushPullContainer).init();

initDatePicker(); // Used for deploy token "expires at" field

fileUpload('.js-choose-file', '.js-object-map-input');

initSearchSettings();

mountBranchRules(document.getElementById('js-branch-rules'));
mountDefaultBranchSelector(document.querySelector('.js-select-default-branch'));
