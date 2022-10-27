import { trackSaasTrialGroup } from '~/google_tag_manager';
import { initNamespaceSelector } from 'ee/trials/init_namespace_selector';

trackSaasTrialGroup();
initNamespaceSelector();
