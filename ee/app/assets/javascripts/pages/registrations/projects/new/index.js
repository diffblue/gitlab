import initProjectVisibilitySelector from '~/project_visibility';
import initProjectNew from '~/projects/project_new';
import { trackSaasTrialProject, trackSaasTrialProjectImport } from '~/google_tag_manager';

initProjectVisibilitySelector();
initProjectNew.bindEvents();

trackSaasTrialProject();
trackSaasTrialProjectImport();
