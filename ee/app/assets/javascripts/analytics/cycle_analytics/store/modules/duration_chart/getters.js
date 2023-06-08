import { getDurationChartData, getDurationOverviewChartData } from '../../../utils';

export const durationChartPlottableData = (state, _, rootState) => {
  const { createdAfter, createdBefore, selectedStage } = rootState;
  const { durationData } = state;
  const selectedStageDurationData = durationData.find((stage) => stage.id === selectedStage.id);

  if (!selectedStageDurationData?.data?.length) {
    return [];
  }

  return getDurationChartData([selectedStageDurationData], createdAfter, createdBefore);
};

export const hasPlottableData = ({ durationData = [] }) =>
  durationData.some(({ data }) => data.length);

export const durationOverviewChartPlottableData = (state) => {
  const { durationData } = state;

  if (!hasPlottableData({ durationData })) {
    return [];
  }

  return getDurationOverviewChartData(durationData);
};
