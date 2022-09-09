import { getDurationChartData } from '../../../utils';

export const hasPlottableData = ({ durationData = [] }) =>
  durationData.some(({ data }) => data.length);

export const durationChartPlottableData = (state, _, rootState, rootGetters) => {
  const { createdAfter, createdBefore, selectedStage } = rootState;
  const { durationData } = state;
  const { isOverviewStageSelected } = rootGetters;
  const selectedStagesDurationData = isOverviewStageSelected
    ? durationData
    : durationData.filter((stage) => stage.id === selectedStage.id);

  if (!hasPlottableData({ durationData: selectedStagesDurationData })) {
    return [];
  }

  const plottableData = getDurationChartData(
    selectedStagesDurationData,
    createdAfter,
    createdBefore,
  );

  return plottableData;
};
