import { numberToHumanSize } from '~/lib/utils/number_utils';
import { PROJECT_STORAGE_TYPES } from './constants';

export const getStorageTypesFromProjectStatistics = (projectStatistics, helpLinks = {}) =>
  PROJECT_STORAGE_TYPES.reduce((types, currentType) => {
    const helpPathKey = currentType.id.replace(`Size`, `HelpPagePath`);
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
