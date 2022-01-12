import { numberToHumanSize, bytesToKiB } from '~/lib/utils/number_utils';
import { getFormatter, SUPPORTED_FORMATS } from '~/lib/utils/unit_format';
import { PROJECT_STORAGE_TYPES, STORAGE_USAGE_THRESHOLDS } from './constants';

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

 * @param {Number} size size in bytes
 * @returns {String}
 */
export const formatUsageSize = (size) => {
  const formatDecimalBytes = getFormatter(SUPPORTED_FORMATS.kibibytes);
  return formatDecimalBytes(bytesToKiB(size), 1);
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
 * if we should render N/A
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
    : 'N/A';

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

export const getStorageTypesFromProjectStatistics = (projectStatistics, helpLinks = {}) =>
  PROJECT_STORAGE_TYPES.reduce((types, currentType) => {
    const helpPathKey = currentType.id.replace(`Size`, ``);
    const helpPath = helpLinks[helpPathKey];

    return types.concat({
      storageType: {
        ...currentType,
        helpPath,
      },
      value: projectStatistics[currentType.id],
    });
  }, []);

/**
 * This method parses the results from `getProjectStorageStatistics` call.
 *
 * @param {Object} data graphql result
 * @returns {Object}
 */
export const parseGetProjectStorageResults = (data, helpLinks) => {
  const projectStatistics = data?.project?.statistics;
  if (!projectStatistics) {
    return {};
  }
  const { storageSize } = projectStatistics;
  const storageTypes = getStorageTypesFromProjectStatistics(projectStatistics, helpLinks);

  return {
    storage: {
      totalUsage: numberToHumanSize(storageSize, 1),
      storageTypes,
    },
    statistics: projectStatistics,
  };
};

/**
 * Creates a sorting function to sort storage types by usage in the graph and in the table
 *
 * @param {string} storageUsageKey key storing value of storage usage
 * @returns {Function} sorting function
 */
export function descendingStorageUsageSort(storageUsageKey) {
  return (a, b) => b[storageUsageKey] - a[storageUsageKey];
}
