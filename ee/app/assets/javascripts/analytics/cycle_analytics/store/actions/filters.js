import * as types from '../mutation_types';

const refreshData = ({ selectedStage, isOverviewStageSelected, dispatch }) => {
  if (selectedStage && !isOverviewStageSelected) dispatch('fetchStageData', selectedStage.id);
  return dispatch('fetchCycleAnalyticsData');
};

export const setSelectedProjects = (
  { commit, dispatch, getters: { isOverviewStageSelected }, state: { selectedStage } },
  projects,
) => {
  commit(types.SET_SELECTED_PROJECTS, projects);
  return refreshData({ dispatch, selectedStage, isOverviewStageSelected });
};

export const setDateRange = (
  { commit, dispatch, getters: { isOverviewStageSelected }, state: { selectedStage } },
  { createdAfter, createdBefore },
) => {
  commit(types.SET_DATE_RANGE, { createdBefore, createdAfter });
  if (selectedStage && !isOverviewStageSelected) dispatch('fetchStageData', selectedStage.id);
  return dispatch('fetchCycleAnalyticsData');
};

export const setFilters = ({
  dispatch,
  getters: { isOverviewStageSelected },
  state: { selectedStage },
}) => {
  return refreshData({ dispatch, isOverviewStageSelected, selectedStage });
};

export const updateStageTablePagination = (
  { commit, dispatch, state: { selectedStage } },
  paginationParams,
) => {
  commit(types.SET_PAGINATION, paginationParams);
  return dispatch('fetchStageData', selectedStage.id);
};
