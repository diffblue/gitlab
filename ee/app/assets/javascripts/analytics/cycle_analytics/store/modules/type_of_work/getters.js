import { getTasksByTypeData } from '../../../utils';

export const selectedTasksByTypeFilters = (state = {}, _, rootState = {}, rootGetters = {}) => {
  const { selectedLabelIds = [], subject } = state;
  const { currentGroup, createdAfter = null, createdBefore = null } = rootState;
  const { selectedProjectIds = [] } = rootGetters;
  return {
    currentGroup,
    selectedProjectIds,
    createdAfter,
    createdBefore,
    selectedLabelIds,
    subject,
  };
};

export const tasksByTypeChartData = ({ data = [] } = {}, _, rootState = {}) => {
  const { createdAfter = null, createdBefore = null } = rootState;
  return data.length
    ? getTasksByTypeData({ data, createdAfter, createdBefore })
    : { groupBy: [], data: [] };
};
