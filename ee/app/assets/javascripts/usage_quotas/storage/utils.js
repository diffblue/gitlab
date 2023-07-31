import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';

/**
 * This method parses the results from `getNamespaceStorageStatistics`
 * call.
 *
 * `rootStorageStatistics` will be sent as null until an
 * event happens to trigger the storage count.
 * For that reason we have to verify if `storageSize` is sent or
 * if we should render 'Not applicable.'
 *
 * @param {Object} data graphql result
 * @returns {Object}
 */
export const parseGetStorageResults = (data) => {
  const {
    namespace: {
      projects,
      storageSizeLimit,
      totalRepositorySize,
      containsLockedProjects,
      totalRepositorySizeExcess,
      rootStorageStatistics = {},
      actualRepositorySizeLimit,
      additionalPurchasedStorageSize,
      repositorySizeExcessProjectCount,
    },
  } = data || {};

  const totalUsage = rootStorageStatistics?.storageSize
    ? numberToHumanSize(rootStorageStatistics.storageSize)
    : __('Not applicable.');

  return {
    projects: {
      data: projects.nodes,
      pageInfo: projects.pageInfo,
    },
    additionalPurchasedStorageSize,
    actualRepositorySizeLimit,
    containsLockedProjects,
    repositorySizeExcessProjectCount,
    totalRepositorySize,
    totalRepositorySizeExcess,
    totalUsage,
    rootStorageStatistics,
    limit: storageSizeLimit,
  };
};
