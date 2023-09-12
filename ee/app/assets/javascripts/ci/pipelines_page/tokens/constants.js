import { s__ } from '~/locale';
import { PIPELINE_SOURCES as CE_PIPELINE_SOURCES } from '~/ci/pipelines_page/tokens/constants';

const EE_PIPELINE_SOURCES = [
  {
    text: s__('PipelineSource|On-Demand DAST Scan'),
    value: 'ondemand_dast_scan',
  },
  {
    text: s__('PipelineSource|On-Demand DAST Validation'),
    value: 'ondemand_dast_validation',
  },
  {
    text: s__('Pipeline|Source|Security Policy'),
    value: 'security_orchestration_policy',
  },
];

export const PIPELINE_SOURCES = [...CE_PIPELINE_SOURCES, ...EE_PIPELINE_SOURCES];
