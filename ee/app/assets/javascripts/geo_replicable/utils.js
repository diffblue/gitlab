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
 * so we ensure that we always hit the current node, if on a secondary.
 */
export const gqGeoClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
    path: '/api/v4/geo/graphql',
  },
);

/**
 * This is a proxy of the /api/v4/geo/graphql of a specific node,
 * so we're requesting data directly from a secondary's GraphQL endpoint.
 */
export const gqGeoClientForSecondaryNodeId = (secondaryNodeId) =>
  createGqClient(
    {},
    {
      fetchPolicy: fetchPolicies.NO_CACHE,
      path: `/api/v4/geo/node_proxy/${secondaryNodeId}/graphql`,
    },
  );

/**
 * Slight optimization, if we know the target node is also the current node, or
 * if we don't know what's the target node, we look at the current node instead,
 * by going to /api/v4/geo/graphql - an alias for /api/v4/graphql that bypasses
 * the Geo proxy (so we always hit the current node here, if on a secondary).
 *
 * @param {string} currentNodeId - current node id
 * @param {string} targetNodeId - target node id
 * @returns {Object} - GraphQL client
 */
export const getGraphqlClient = (currentNodeId, targetNodeId) => {
  if (targetNodeId !== undefined && currentNodeId !== targetNodeId) {
    return gqGeoClientForSecondaryNodeId(targetNodeId);
  }

  return gqGeoClient;
};
