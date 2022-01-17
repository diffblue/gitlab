import { helpPagePath } from '~/helpers/help_page_helper';

export const SELECTIVE_SYNC_SHARDS = 'selectiveSyncShards';
export const SELECTIVE_SYNC_NAMESPACES = 'selectiveSyncNamespaceIds';
export const VALIDATION_FIELD_KEYS = {
  NAME: 'name',
  URL: 'url',
  REPOS_MAX_CAPACITY: 'reposMaxCapacity',
  FILES_MAX_CAPACITY: 'filesMaxCapacity',
  CONTAINER_REPOSITORIES_MAX_CAPACITY: 'containerRepositoriesMaxCapacity',
  VERIFICATION_MAX_CAPACITY: 'verificationMaxCapacity',
  MINIMUM_REVERIFICATION_INTERVAL: 'minimumReverificationInterval',
};

export const NODE_NAME_MORE_INFO = helpPagePath('user/admin_area/geo_nodes.html', {
  anchor: 'common-settings',
});

export const NODE_INTERNAL_URL_MORE_INFO = helpPagePath('user/admin_area/geo_nodes.html', {
  anchor: 'set-up-the-internal-urls',
});

export const SELECTIVE_SYNC_MORE_INFO = helpPagePath(
  'administration/geo/replication/configuration.html',
  { anchor: 'selective-synchronization' },
);

export const OBJECT_STORAGE_MORE_INFO = helpPagePath(
  'administration/geo/replication/object_storage.html',
);

export const OBJECT_STORAGE_BETA = helpPagePath(
  'administration/geo/replication/object_storage.html',
  { anchor: 'enabling-gitlab-managed-object-storage-replication' },
);

export const REVERIFICATION_MORE_INFO = helpPagePath(
  'administration/geo/disaster_recovery/background_verification.html',
  { anchor: 'repository-re-verification' },
);

export const BACKFILL_MORE_INFO = helpPagePath('user/admin_area/geo_nodes.html', {
  anchor: 'geo-backfill',
});
