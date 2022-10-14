import { __, s__ } from '~/locale';

export const JOB_STATUS_GROUP_SUCCESS = 'success';

export const STATUS_BADGE_VARIANTS = {
  success: 'success',
  passed: 'success',
  error: 'danger',
  failed: 'danger',
  pending: 'warning',
  'waiting-for-resource': 'warning',
  'failed-with-warnings': 'warning',
  'success-with-warnings': 'warning',
  running: 'info',
  canceled: 'neutral',
  disabled: 'neutral',
  scheduled: 'neutral',
  manual: 'neutral',
  notification: 'muted',
  preparing: 'muted',
  created: 'muted',
  skipped: 'muted',
  notfound: 'muted',
};

export const i18n = {
  download: __('Download'),
  browse: s__('Artifacts|Browse'),
  delete: __('Delete'),
  expired: __('Expired'),
  destroyArtifactError: s__('Artifacts|An error occurred while deleting the artifact'),
  fetchArtifactsError: s__('Artifacts|An error occurred while retrieving job artifacts'),
  artifactsLabel: __('Artifacts'),
  jobLabel: __('Job'),
  sizeLabel: __('Size'),
  createdLabel: __('Created'),
};

export const JOBS_PER_PAGE = 20;

export const INITIAL_PAGINATION_STATE = {
  currentPage: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: JOBS_PER_PAGE,
  lastPageSize: null,
};

export const ARCHIVE_FILE_TYPE = 'ARCHIVE';
