export const PROJECT_ON_DEMAND_SCAN_COUNTS_ETAG_MOCK = `/api/graphql:on_demand_scan/counts/namespace/project`;

export const RUNNER_TAG_LIST_MOCK = {
  data: {
    project: {
      runners: {
        nodes: [
          {
            id: 'id1',
            name: 'runner1',
            tagList: ['macos', 'linux', 'docker'],
          },
          {
            id: 'id2',
            name: 'runner2',
            tagList: ['backup', 'linux', 'development'],
          },
          {
            id: 'id3',
            name: 'runner3',
            tagList: ['east-c', 'mango', 'maven'],
          },
        ],
      },
    },
  },
};
