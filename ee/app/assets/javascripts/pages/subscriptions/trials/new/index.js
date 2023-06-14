import { initTrialCreateLeadForm } from 'ee/trials/init_create_lead_form';
import { trackSaasTrialGroup } from '~/google_tag_manager';
import 'ee/trials/track_trial_user_errors';
import { initNamespaceSelector } from 'ee/trials/init_namespace_selector';

trackSaasTrialGroup();
initTrialCreateLeadForm();
initNamespaceSelector();
