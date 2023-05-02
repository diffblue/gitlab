import { isArray } from 'lodash';
import Visibility from 'visibilityjs';

/**
 * Ids generated by GraphQL endpoints are usually in the format
 * gid://gitlab/Environments/123. This method checks if the passed id follows that format
 *
 * @param {String|Number} id The id value
 * @returns {Boolean}
 */
export const isGid = (id) => {
  if (typeof id === 'string' && id.startsWith('gid://gitlab/')) {
    return true;
  }

  return false;
};

const parseGid = (gid) => parseInt(`${gid}`.replace(/gid:\/\/gitlab\/.*\//g, ''), 10);

/**
 * Ids generated by GraphQL endpoints are usually in the format
 * gid://gitlab/Environments/123. This method extracts Id number
 * from the Id path
 *
 * @param {String} gid GraphQL global ID
 * @returns {Number}
 */
export const getIdFromGraphQLId = (gid = '') => {
  const parsedGid = parseGid(gid);
  return Number.isInteger(parsedGid) ? parsedGid : null;
};

export const MutationOperationMode = {
  Append: 'APPEND',
  Remove: 'REMOVE',
  Replace: 'REPLACE',
};

/**
 * Ids generated by GraphQL endpoints are usually in the format
 * gid://gitlab/Groups/123. This method takes a type and an id
 * and interpolates the 2 values into the expected GraphQL ID format.
 *
 * @param {String} type The entity type
 * @param {String|Number} id The id value
 * @returns {String}
 */
export const convertToGraphQLId = (type, id) => {
  if (typeof type !== 'string') {
    throw new TypeError(`type must be a string; got ${typeof type}`);
  }

  if (!['number', 'string'].includes(typeof id)) {
    throw new TypeError(`id must be a number or string; got ${typeof id}`);
  }

  if (isGid(id)) {
    return id;
  }

  return `gid://gitlab/${type}/${id}`;
};

/**
 * Ids generated by GraphQL endpoints are usually in the format
 * gid://gitlab/Groups/123. This method takes a type and an
 * array of ids and tranforms the array values into the expected
 * GraphQL ID format.
 *
 * @param {String} type The entity type
 * @param {Array} ids An array of id values
 * @returns {Array}
 */
export const convertToGraphQLIds = (type, ids) => ids.map((id) => convertToGraphQLId(type, id));

/**
 * Ids generated by GraphQL endpoints are usually in the format
 * gid://gitlab/Groups/123. This method takes an array of
 * GraphQL Ids and converts them to a number.
 *
 * @param {Array} ids An array of GraphQL IDs
 * @returns {Array}
 */
export const convertFromGraphQLIds = (ids) => {
  if (!isArray(ids)) {
    throw new TypeError(`ids must be an array; got ${typeof ids}`);
  }

  return ids.map((id) => getIdFromGraphQLId(id));
};

/**
 * Ids generated by GraphQL endpoints are usually in the format
 * gid://gitlab/Groups/123. This method takes an array of nodes
 * and converts the `id` properties from a GraphQL Id to a number.
 *
 * @param {Array} nodes An array of nodes with an `id` property
 * @returns {Array}
 */
export const convertNodeIdsFromGraphQLIds = (nodes) => {
  if (!isArray(nodes)) {
    throw new TypeError(`nodes must be an array; got ${typeof nodes}`);
  }

  return nodes.map((node) => (node.id ? { ...node, id: getIdFromGraphQLId(node.id) } : node));
};

/**
 * This function takes a GraphQL query data as a required argument and
 * the field name to resolve as an optional argument
 * and returns resolved field's data or an empty array
 * @param {Object} queryData
 * @param {String} nodesField (in most cases it will be 'nodes')
 * @returns {Array}
 */
export const getNodesOrDefault = (queryData, nodesField = 'nodes') => {
  return queryData?.[nodesField] ?? [];
};

export const toggleQueryPollingByVisibility = (queryRef, interval = 10000) => {
  const stopStartQuery = (query) => {
    if (!Visibility.hidden()) {
      query.startPolling(interval);
    } else {
      query.stopPolling();
    }
  };

  stopStartQuery(queryRef);
  Visibility.change(stopStartQuery.bind(null, queryRef));
};

export const etagQueryHeaders = (featureCorrelation, etagResource = '') => {
  return {
    fetchOptions: {
      method: 'GET',
    },
    headers: {
      'X-GITLAB-GRAPHQL-FEATURE-CORRELATION': featureCorrelation,
      'X-GITLAB-GRAPHQL-RESOURCE-ETAG': etagResource,
      'X-Requested-With': 'XMLHttpRequest',
    },
  };
};
