/* eslint-disable no-new */
import initSettingsPanels from '~/settings_panels';
import ProtectedBranchEditList from 'ee/protected_branches/protected_branch_edit_list';
import ProtectedBranchCreate from '~/protected_branches/protected_branch_create';

initSettingsPanels();
new ProtectedBranchCreate({ hasLicense: true });
new ProtectedBranchEditList();
