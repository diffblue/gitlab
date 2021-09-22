import { PAGE_SIZE } from './constants';

export default () => ({
  projectPath: null,
  pipelineIid: null,
  endpoint: '',
  allCodequalityIssues: [],
  codequalityIssues: [],
  isLoadingCodequality: false,
  loadingCodequalityFailed: false,
  codeQualityError: null,
  pageInfo: {
    page: 1,
    perPage: PAGE_SIZE,
    total: 0,
    count: 0,
    currentPage: 1,
    startCursor: '',
    endCursor: '',
    first: PAGE_SIZE,
    after: '',
    hasNextPage: false,
  },
});
