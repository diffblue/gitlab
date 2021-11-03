import { PAGE_SIZE } from './constants';

export default () => ({
  endpoint: '',
  allCodequalityIssues: [],
  isLoadingCodequality: false,
  loadingCodequalityFailed: false,
  codeQualityError: null,
  pageInfo: {
    page: 1,
    perPage: PAGE_SIZE,
    total: 0,
  },
});
