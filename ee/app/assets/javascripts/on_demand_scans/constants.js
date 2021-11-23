import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const HELP_PAGE_PATH = helpPagePath('user/application_security/dast/index', {
  anchor: 'on-demand-scans',
});
export const LEARN_MORE_TEXT = s__(
  'OnDemandScans|%{learnMoreLinkStart}Learn more about on-demand scans%{learnMoreLinkEnd}.',
);

export const PIPELINE_TABS_KEYS = ['all', 'running', 'finished'];
export const PIPELINES_PER_PAGE = 20;
export const PIPELINES_POLL_INTERVAL = 1000;
export const PIPELINES_COUNT_POLL_INTERVAL = 1000;
export const PIPELINES_SCOPE_RUNNING = 'RUNNING';
export const PIPELINES_SCOPE_FINISHED = 'FINISHED';

export const BASE_TABS_TABLE_FIELDS = [
  {
    label: __('Status'),
    key: 'detailedStatus',
    columnClass: 'gl-w-15',
  },
  {
    label: __('Name'),
    key: 'dastProfile.name',
  },
  {
    label: s__('OnDemandScans|Scan type'),
    key: 'scanType',
    columnClass: 'gl-w-13',
  },
  {
    label: s__('OnDemandScans|Target'),
    key: 'dastProfile.dastSiteProfile.targetUrl',
  },
  {
    label: __('Start date'),
    key: 'createdAt',
    columnClass: 'gl-w-15',
  },
  {
    label: __('Pipeline'),
    key: 'id',
    columnClass: 'gl-w-13',
  },
];
