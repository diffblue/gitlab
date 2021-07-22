import { __, s__ } from '~/locale';

export const SORT_FIELDS = {
  name: s__('Dependencies|Component name'),
  packager: s__('Dependencies|Packager'),
  severity: s__('Vulnerability|Severity'),
};

export const SORT_ASCENDING = 'asc';
export const SORT_DESCENDING = 'desc';

export const REPORT_STATUS = {
  ok: 'ok',
  jobNotSetUp: 'job_not_set_up',
  jobFailed: 'job_failed',
  noDependencies: 'no_dependencies',
  incomplete: 'no_dependency_files',
};

export const FILTER = {
  all: 'all',
  vulnerable: 'vulnerable',
};

export const FETCH_ERROR_MESSAGE = __(
  'Error fetching the dependency list. Please check your network connection and try again.',
);
