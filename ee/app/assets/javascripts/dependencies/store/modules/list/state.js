import { FILTER, REPORT_STATUS } from './constants';

export default () => ({
  endpoint: '',
  exportEndpoint: '',
  fetchingInProgress: false,
  initialized: false,
  isLoading: false,
  errorLoading: false,
  dependencies: [],
  pageInfo: {
    total: 0,
  },
  reportInfo: {
    status: REPORT_STATUS.ok,
    jobPath: '',
    generatedAt: '',
  },
  filter: FILTER.all,
  sortField: null,
  sortOrder: null,
});
