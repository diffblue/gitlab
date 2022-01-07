import { shouldQrtlyReconciliationMount } from 'ee/billings/qrtly_reconciliation';
import initGitlabVersionCheck from '~/gitlab_version_check';

shouldQrtlyReconciliationMount();
initGitlabVersionCheck();
