export default () => ({
  provider: '',
  repositories: [],
  namespaces: [],
  customImportTargets: {},
  isLoadingRepos: false,
  isLoadingNamespaces: false,
  ciCdOnly: false,
  filter: '',
  pageInfo: {
    page: 0,
    startCursor: null,
    endCursor: null,
    hasNextPage: true,
  },
});
