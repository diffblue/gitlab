import { getTasksByTypeData } from '../../../utils';

export const selectedLabelNames = ({ selectedLabels = [] }) => {
  return selectedLabels.map(({ title }) => title);
};

export const selectedLabelIds = ({ selectedLabels = [] }) => {
  return selectedLabels.map(({ id }) => id);
};

export const selectedTasksByTypeFilters = (state = {}, _, rootState = {}, rootGetters = {}) => {
  const { subject } = state;
  const { currentGroup, createdAfter = null, createdBefore = null } = rootState;
  const { selectedProjectIds = [] } = rootGetters;
  return {
    currentGroup,
    selectedProjectIds,
    createdAfter,
    createdBefore,
    subject,
  };
};

export const tasksByTypeChartData = ({ data = [] } = {}, _, rootState = {}) => {
  const { createdAfter = null, createdBefore = null } = rootState;
  return data.length
    ? getTasksByTypeData({ data, createdAfter, createdBefore })
    : { groupBy: [], data: [] };
};
