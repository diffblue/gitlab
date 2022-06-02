import initPolicyEditorApp from 'ee/security_orchestration/policy_editor';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

initPolicyEditorApp(document.getElementById('js-group-policy-builder-app'), NAMESPACE_TYPES.GROUP);
