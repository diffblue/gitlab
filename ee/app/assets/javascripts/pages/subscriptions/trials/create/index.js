import 'ee/trials/track_trial_user_errors';
import { initTrialCreateLeadForm } from 'ee/trials/init_create_lead_form';
import { initErrorAlert } from 'ee/trials/init_error_alert';
import { initNamespaceSelector } from 'ee/trials/init_namespace_selector';

initTrialCreateLeadForm();
initNamespaceSelector();
initErrorAlert();
