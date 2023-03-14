export const MOCK_SELECTIVE_SYNC_TYPES = {
  ALL: {
    label: 'All projects',
    value: '',
  },
  NAMESPACES: {
    label: 'Projects in certain groups',
    value: 'namespaces',
  },
  SHARDS: {
    label: 'Projects in certain storage shards',
    value: 'shards',
  },
};

export const MOCK_SYNC_SHARDS = [
  {
    label: 'Shard 1',
    value: 'shard1',
  },
  {
    label: 'Shard 2',
    value: 'shard2',
  },
  {
    label: 'Shard 3',
    value: 'shard3',
  },
];

export const MOCK_SYNC_NAMESPACES = [
  {
    name: 'Namespace 1',
    id: 'namespace1',
  },
  {
    name: 'Namespace 2',
    id: 'namespace2',
  },
  {
    name: 'namespace 3',
    id: 'Namespace3',
  },
];

export const STRING_OVER_255 =
  'ynzF7m5XjQQAlHfzPpDLhiaFZH84Zds47cHLWpRqRGTKjmXCe4frDWjIrjzfchpoOOX2jmK4wLRbyw9oTuzFmMPZhTK14mVoZTfaLXOBeH9F0S1XT3v7kszTC4cMLJvNsto7iSQ2PGxTGpZXFSQTL2UuMTTQ5GiARLVLS7CEEW75orbJh5kbKM6CRXpu4EliGRKKSwHMtXQ2ZDi01yvWOXc7ymNHeEooT4aDC7xq7g1uslbq1aVEWylVixSDARob';

export const MOCK_SITE = {
  id: 1,
  name: 'Mock Site',
  url: 'https://mock_site.gitlab.com',
  primary: false,
  internalUrl: '',
  selectiveSyncType: '',
  selectiveSyncNamespaceIds: [],
  selectiveSyncShards: [],
  reposMaxCapacity: 25,
  filesMaxCapacity: 10,
  verificationMaxCapacity: 100,
  containerRepositoriesMaxCapacity: 10,
  minimumReverificationInterval: 7,
  syncObjectStorage: false,
};

export const MOCK_ERROR_MESSAGE = {
  name: ["can't be blank"],
  url: ["can't be blank", 'must be a valid URL'],
};

export const MOCK_SITES_PATH = 'gitlab/admin/geo/sites';
