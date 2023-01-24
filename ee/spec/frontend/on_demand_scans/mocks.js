export const PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK = `/api/graphql:on_demand_scan/counts/namespace/project`;

export const RUNNER_TAG_LIST_MOCK = [
  {
    id: 'gid://gitlab/Ci::Runner/1',
    status: 'ONLINE',
    tagList: ['macos', 'linux', 'docker'],
  },
  {
    id: 'gid://gitlab/Ci::Runner/2',
    status: 'ONLINE',
    tagList: ['backup', 'linux', 'development'],
  },
];
