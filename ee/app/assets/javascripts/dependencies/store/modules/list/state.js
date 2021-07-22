import { FILTER, REPORT_STATUS, SORT_FIELD_ORDER } from './constants';

export default () => {
  const sortField = 'severity';

  return {
    endpoint: '',
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
    sortField,
    sortOrder: SORT_FIELD_ORDER[sortField],
  };
};
