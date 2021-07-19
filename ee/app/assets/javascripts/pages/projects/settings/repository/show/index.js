/* eslint-disable no-new */
import ProtectedBranchEditList from 'ee/protected_branches/protected_branch_edit_list';
import ProtectedTagCreate from 'ee/protected_tags/protected_tag_create';
import ProtectedTagEditList from 'ee/protected_tags/protected_tag_edit_list';

import initDatePicker from '~/behaviors/date_picker';
import initDeployKeys from '~/deploy_keys';
import fileUpload from '~/lib/utils/file_upload';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';
import CEProtectedBranchEditList from '~/protected_branches/protected_branch_edit_list';
import CEProtectedTagCreate from '~/protected_tags/protected_tag_create';
import CEProtectedTagEditList from '~/protected_tags/protected_tag_edit_list';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';
import UserCallout from '~/user_callout';
import UsersSelect from '~/users_select';
import EEMirrorRepos from './ee_mirror_repos';

new UsersSelect();
new UserCallout();

initDeployKeys();
initSettingsPanels();

if (document.querySelector('.js-protected-refs-for-users')) {
  new ProtectedBranchCreate({ hasLicense: true });
  new ProtectedBranchEditList();

  new ProtectedTagCreate();
  new ProtectedTagEditList();
} else {
  new ProtectedBranchCreate({ hasLicense: false });
  new CEProtectedBranchEditList();

  new CEProtectedTagCreate();
  new CEProtectedTagEditList();
}

const pushPullContainer = document.querySelector('.js-mirror-settings');
if (pushPullContainer) new EEMirrorRepos(pushPullContainer).init();

initDatePicker(); // Used for deploy token "expires at" field

fileUpload('.js-choose-file', '.js-object-map-input');

initSearchSettings();
