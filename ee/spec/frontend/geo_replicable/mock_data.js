export const MOCK_GEO_REPLICATION_SVG_PATH = 'illustrations/empty-state/geo-replication-empty.svg';

export const MOCK_REPLICABLE_TYPE = 'designs';

export const MOCK_GRAPHQL_REGISTRY = 'designsRegistry';

export const MOCK_GRAPHQL_REGISTRY_CLASS = 'DESIGNS_REGISTRY';

export const MOCK_BASIC_GRAPHQL_DATA = [
  {
    name: 'test 1',
    id: 'git/1',
    state: 'PENDING',
    lastSyncedAt: new Date().toString(),
    verifiedAt: new Date().toString(),
  },
  {
    name: 'test 2',
    id: 'git/2',
    state: 'SYNCED',
    lastSyncedAt: null,
    verifiedAt: null,
  },
];

export const MOCK_GRAPHQL_PAGINATION_DATA = {
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'abc123',
  endCursor: 'abc124',
};

// Query.geoNode to be renamed to Query.geoSite => https://gitlab.com/gitlab-org/gitlab/-/issues/396739
export const MOCK_BASIC_GRAPHQL_QUERY_RESPONSE = {
  geoNode: {
    [MOCK_GRAPHQL_REGISTRY]: {
      pageInfo: MOCK_GRAPHQL_PAGINATION_DATA,
      nodes: MOCK_BASIC_GRAPHQL_DATA,
    },
  },
};
