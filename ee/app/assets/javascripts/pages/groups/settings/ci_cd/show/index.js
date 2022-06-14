import ProtectedEnvironmentCreate from 'ee/group_protected_environments/protected_environment_create';
import { initProtectedEnvironmentEditList } from 'ee/group_protected_environments/protected_environment_edit_list';
import '~/pages/groups/settings/ci_cd/show/index';

// eslint-disable-next-line no-new
new ProtectedEnvironmentCreate();

initProtectedEnvironmentEditList();
