import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import initPolicyEditorApp from 'ee/security_orchestration/policy_editor';

initPolicyEditorApp(document.getElementById('js-group-policy-builder-app'), NAMESPACE_TYPES.GROUP);
