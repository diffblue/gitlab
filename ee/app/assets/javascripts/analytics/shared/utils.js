import dateFormat from 'dateformat';
import { dateFormats } from '~/analytics/shared/constants';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

export const formattedDate = (d) => dateFormat(d, dateFormats.defaultDate);

/**
 * Creates a value stream object from a dataset. Returns null if no valueStreamId is present.
 *
 * @param {Object} dataset - The raw value stream object
 * @returns {Object} - A value stream object
 */
export const buildValueStreamFromJson = (valueStream) => {
  const { id, name, is_custom: isCustom } = valueStream ? JSON.parse(valueStream) : {};
  return id ? { id, name, isCustom } : null;
};

/**
 * Creates an array of stage objects from a json string. Returns an empty array if no stages are present.
 *
 * @param {String} stages - JSON encoded array of stages
 * @returns {Array} - An array of stage objects
 */
const buildDefaultStagesFromJSON = (stages = '') => {
  if (!stages.length) return [];
  return JSON.parse(stages);
};

/**
 * Creates a group object from a dataset. Returns null if no groupId is present.
 *
 * @param {Object} dataset - The container's dataset
 * @returns {Object} - A group object
 */
export const buildGroupFromDataset = (dataset) => {
  const { groupId, groupName, groupFullPath, groupAvatarUrl, groupParentId } = dataset;

  if (groupId) {
    return {
      id: Number(groupId),
      name: groupName,
      full_path: groupFullPath,
      avatar_url: groupAvatarUrl,
      parent_id: groupParentId,
    };
  }

  return null;
};

/**
 * Creates a project object from a dataset. Returns null if no projectId is present.
 *
 * @param {Object} dataset - The container's dataset
 * @returns {Object} - A project object
 */
export const buildProjectFromDataset = (dataset) => {
  const { projectGid, projectName, projectPathWithNamespace, projectAvatarUrl } = dataset;

  if (projectGid) {
    return {
      id: projectGid,
      name: projectName,
      path_with_namespace: projectPathWithNamespace,
      avatar_url: projectAvatarUrl,
    };
  }

  return null;
};

/**
 * Creates an array of project objects from a json string. Returns null if no projects are present.
 *
 * @param {String} data - JSON encoded array of projects
 * @returns {Array} - An array of project objects
 */
const buildProjectsFromJSON = (projects = '') => {
  if (!projects.length) return [];
  return JSON.parse(projects);
};

/**
 * Builds the initial data object for Value Stream Analytics with data loaded from the backend
 *
 * @param {Object} dataset - dataset object paseed to the frontend via data-* properties
 * @returns {Object} - The initial data to load the app with
 */
export const buildCycleAnalyticsInitialData = ({
  valueStream = null,
  groupId = null,
  createdBefore = null,
  createdAfter = null,
  projects = null,
  groupName = null,
  groupFullPath = null,
  groupParentId = null,
  groupAvatarUrl = null,
  labelsPath = '',
  milestonesPath = '',
  defaultStages = null,
  stage = null,
  aggregationEnabled = false,
  aggregationLastRunAt = null,
  aggregationNextRunAt = null,
} = {}) => ({
  selectedValueStream: buildValueStreamFromJson(valueStream),
  group: groupId
    ? convertObjectPropsToCamelCase(
        buildGroupFromDataset({
          groupId,
          groupName,
          groupFullPath,
          groupAvatarUrl,
          groupParentId,
        }),
      )
    : null,
  createdBefore: createdBefore ? new Date(createdBefore) : null,
  createdAfter: createdAfter ? new Date(createdAfter) : null,
  selectedProjects: projects
    ? buildProjectsFromJSON(projects).map(convertObjectPropsToCamelCase)
    : null,
  labelsPath,
  milestonesPath,
  defaultStageConfig: defaultStages
    ? buildDefaultStagesFromJSON(defaultStages).map(({ name, ...rest }) => ({
        ...convertObjectPropsToCamelCase(rest),
        name: capitalizeFirstCharacter(name),
      }))
    : [],
  stage: JSON.parse(stage),
  aggregation: {
    enabled: parseBoolean(aggregationEnabled),
    lastRunAt: aggregationLastRunAt,
    nextRunAt: aggregationNextRunAt,
  },
});
