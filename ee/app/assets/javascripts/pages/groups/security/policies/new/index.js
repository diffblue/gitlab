import initPolicyEditorApp from 'ee/threat_monitoring/policy_editor';
import { NAMESPACE_TYPES } from 'ee/threat_monitoring/constants';

initPolicyEditorApp(document.getElementById('js-group-policy-builder-app'), NAMESPACE_TYPES.GROUP);
