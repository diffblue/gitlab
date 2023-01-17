import { numberToHumanSize, bytesToKiB } from '~/lib/utils/number_utils';
import { gibibytes, kibibytes } from '~/lib/utils/unit_format';
import { __ } from '~/locale';
import { STORAGE_USAGE_THRESHOLDS } from './constants';

export function usageRatioToThresholdLevel(currentUsageRatio) {
  let currentLevel = Object.keys(STORAGE_USAGE_THRESHOLDS)[0];
  Object.keys(STORAGE_USAGE_THRESHOLDS).forEach((thresholdLevel) => {
    if (currentUsageRatio >= STORAGE_USAGE_THRESHOLDS[thresholdLevel])
      currentLevel = thresholdLevel;
  });

  return currentLevel;
}

/**
 * Formats given bytes to formatted human readable size
 *
 * We want to display all units above bytes. Hence
 * converting bytesToKiB before passing it to
 * `getFormatter`

 * @param sizeInBytes
 * @param {String} unitSeparator
 * @returns {String}
 */
export const formatUsageSize = (sizeInBytes, unitSeparator = '') => {
  return kibibytes(bytesToKiB(sizeInBytes), 1, { unitSeparator });
};

/**
 * Parses each project to add additional purchased data
 * equally so that locked projects can be unlocked.
 *
 * For example, if a group contains the below projects and
 * project 2, 3 have exceeded the default 10.0 GB limit.
 * 2 and 3 will remain locked until user purchases additional
 * data.
 *
 * Project 1: 7.0GB
 * Project 2: 13.0GB Locked
 * Project 3: 12.0GB Locked
 *
 * If user purchases X GB, it will be equally available
 * to all the locked projects for further use.
 *
 * @param {Object} data project
 * @param {Number} purchasedStorageRemaining Remaining purchased data in bytes
 * @returns {Object}
 */
export const calculateUsedAndRemStorage = (project, purchasedStorageRemaining) => {
  // We only consider repo size and lfs object size as of %13.5
  const totalCalculatedUsedStorage =
    project.statistics.repositorySize + project.statistics.lfsObjectsSize;
  // If a project size is above the default limit, then the remaining
  // storage value will be calculated on top of the project size as
  // opposed to the default limit.
  // This
  const totalCalculatedStorageLimit =
    totalCalculatedUsedStorage > project.actualRepositorySizeLimit
      ? totalCalculatedUsedStorage + purchasedStorageRemaining
      : project.actualRepositorySizeLimit + purchasedStorageRemaining;
  return {
    ...project,
    totalCalculatedUsedStorage,
    totalCalculatedStorageLimit,
  };
};
/**
 * Parses projects coming in from GraphQL response
 * and patches each project with purchased related
 * data
 *
 * @param {Array} params.projects list of projects
 * @param {Number} params.additionalPurchasedStorageSize Amt purchased in bytes
 * @param {Number} params.totalRepositorySizeExcess Sum of excess amounts on all projects
 * @returns {Array}
 */
export const parseProjects = ({
  projects,
  additionalPurchasedStorageSize = 0,
  totalRepositorySizeExcess = 0,
}) => {
  const purchasedStorageRemaining = Math.max(
    0,
    additionalPurchasedStorageSize - totalRepositorySizeExcess,
  );

  return projects.nodes.map((project) =>
    calculateUsedAndRemStorage(project, purchasedStorageRemaining),
  );
};

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
      data: parseProjects({
        projects,
        additionalPurchasedStorageSize,
        totalRepositorySizeExcess,
      }),
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

/**
 * The formatUsageSize method returns
 * value along with the unit. However, the unit
 * and the value needs to be separated so that
 * they can have different styles. The method
 * splits the value into value and unit.
 *
 * @params {Number} size size in bytes
 * @returns {Object} value and unit of formatted size
 */
export function formatSizeAndSplit(sizeInBytes) {
  if (sizeInBytes === null) {
    return null;
  }
  /**
   * we're using a special separator to help us split the formatted value properly,
   * the separator won't be shown in the output
   */
  const unitSeparator = '@';
  const format = sizeInBytes === 0 ? gibibytes : kibibytes;
  const [value, unit] = format(bytesToKiB(sizeInBytes), 1, { unitSeparator }).split(unitSeparator);
  return { value, unit };
}
