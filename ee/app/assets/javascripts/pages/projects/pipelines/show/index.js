import initCCValidationRequiredAlert from 'ee/credit_card_validation_required_alert';
import initPipelineSecurityDashboard from 'ee/security_dashboard/pipeline_init';
import initPipelines from '~/pages/projects/pipelines/init_pipelines';
import initPipelineDetails from '~/pipelines/pipeline_details_bundle';
import initCodequalityReport from './codequality_report';
import initLicenseReport from './license_report';

initPipelines();
initPipelineDetails();
initPipelineSecurityDashboard();
initLicenseReport();
initCodequalityReport();
initCCValidationRequiredAlert();
