import { s__ } from '~/locale';

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
  download: s__('Artifacts|Download'),
  browse: s__('Artifacts|Browse'),
  delete: s__('Artifacts|Delete'),
  expired: s__('Artifacts|Expired'),
  destroyArtifactError: s__('Artifacts|An error occurred while deleting the artifact'),
  fetchArtifactsError: s__('Artifacts|An error occurred while retrieving job artifacts'),
  artifactsLabel: s__('Artifacts|Artifacts'),
  jobLabel: s__('Artifacts|Job'),
  sizeLabel: s__('Artifacts|Size'),
  createdLabel: s__('Artifacts|Created'),
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
