import createGqClient, { fetchPolicies } from '~/lib/graphql';

/*
  This file uses a NO_CACHE policy due to the need for Geo data to always be fresh.
  The UI this serves is used to watch the "syncing" process of items and their statuses
  will need to be constantly re-queried as the user navigates around to not mistakenly
  think the sync process is broken.
*/

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

/**
 * This is an alias for /api/v4/graphql that bypasses the Geo proxy,
 * so we ensure that we always hit the current site, if on a secondary.
 */
export const gqGeoClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
    path: '/api/v4/geo/graphql',
  },
);

/**
 * This is a proxy of the /api/v4/geo/graphql of a specific site,
 * so we're requesting data directly from a secondary's GraphQL endpoint.
 */
export const gqGeoClientForSecondarySiteId = (secondarySiteId) =>
  createGqClient(
    {},
    {
      fetchPolicy: fetchPolicies.NO_CACHE,
      // geo/node_proxy to be renamed geo/site_proxy => https://gitlab.com/gitlab-org/gitlab/-/issues/396741
      path: `/api/v4/geo/node_proxy/${secondarySiteId}/graphql`,
    },
  );

/**
 * Slight optimization, if we know the target site is also the current site, or
 * if we don't know what's the target site, we look at the current site instead,
 * by going to /api/v4/geo/graphql - an alias for /api/v4/graphql that bypasses
 * the Geo proxy (so we always hit the current site here, if on a secondary).
 *
 * @param {string} currentSiteId - current site id
 * @param {string} targetSiteId - target site id
 * @returns {Object} - GraphQL client
 */
export const getGraphqlClient = (currentSiteId, targetSiteId) => {
  if (targetSiteId !== undefined && currentSiteId !== targetSiteId) {
    return gqGeoClientForSecondarySiteId(targetSiteId);
  }

  return gqGeoClient;
};
