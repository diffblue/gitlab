import { s__ } from '~/locale';

export const LIST_EXCLUSIONS_ENDPOINT = '/api/:version/namespaces/storage/limit_exclusions';

export const exclusionListFetchError = s__(
  'NamespaceLimits|There was an error fetching the exclusion list, try refreshing the page.',
);

export const excludedNamespacesDescription = s__(
  "NamespaceLimits|These namespaces won't receive any notifications nor any degraded functionality while they remain on this list",
);
