import { getDurationChartData } from '../../../utils';

export const durationChartPlottableData = (state, _, rootState, rootGetters) => {
  const { createdAfter, createdBefore, selectedStage } = rootState;
  const { durationData } = state;
  const { isOverviewStageSelected } = rootGetters;
  const selectedStagesDurationData = isOverviewStageSelected
    ? durationData.filter((stage) => stage.selected)
    : durationData.filter((stage) => stage.id === selectedStage.id);
  const plottableData = getDurationChartData(
    selectedStagesDurationData,
    createdAfter,
    createdBefore,
  );

  return plottableData.length ? plottableData : [];
};
