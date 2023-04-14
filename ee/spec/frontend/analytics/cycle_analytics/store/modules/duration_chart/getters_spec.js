import * as getters from 'ee/analytics/cycle_analytics/store/modules/duration_chart/getters';
import { createdAfter, createdBefore } from 'jest/analytics/cycle_analytics/mock_data';
import {
  transformedDurationData,
  durationOverviewChartPlottableData as mockDurationOverviewChartPlottableData,
} from '../../../mock_data';

const rootState = {
  createdAfter,
  createdBefore,
};

describe('DurationChart getters', () => {
  const [selectedStage] = transformedDurationData;
  const rootGetters = { isOverviewStageSelected: false };
  const selectedStageDurationData = [
    ['2019-01-01', 13],
    ['2019-01-02', 27],
  ];

  const stateWithDurationData = {
    durationData: transformedDurationData,
  };

  const stateWithDurationZeros = {
    durationData: [
      { data: [{ average_duration_in_seconds: 0 }] },
      { data: [{ average_duration_in_seconds: null }] },
    ],
  };

  describe('hasPlottableData', () => {
    it('returns false if there is no data', () => {
      expect(getters.hasPlottableData({ durationData: [] })).toBe(false);
    });

    it('returns true if there is plottable data', () => {
      expect(getters.hasPlottableData(stateWithDurationData)).toBe(true);
    });

    it('returns true if the values are 0', () => {
      expect(getters.hasPlottableData(stateWithDurationZeros)).toBe(true);
    });
  });

  describe('durationChartPlottableData', () => {
    describe('with a VSA stage selected', () => {
      beforeEach(() => {
        rootState.selectedStage = selectedStage;
      });

      it('returns plottable data for the currently selected stage', () => {
        const res = getters.durationChartPlottableData(
          stateWithDurationData,
          getters,
          rootState,
          rootGetters,
        );

        expect(res).toEqual(expect.arrayContaining(selectedStageDurationData));
      });

      it('returns an empty array if there is no plottable data for the selected stage', () => {
        const res = getters.durationChartPlottableData(
          { durationData: [] },
          getters,
          rootState,
          rootGetters,
        );

        expect(res).toEqual([]);
      });
    });

    describe('with the overview stage selected', () => {
      beforeEach(() => {
        rootGetters.isOverviewStageSelected = true;
      });

      it('returns plottable data for all available stages', () => {
        const res = getters.durationChartPlottableData(
          { ...stateWithDurationData, isOverviewStageSelected: true },
          getters,
          rootState,
          rootGetters,
        );

        expect(res).toEqual(expect.arrayContaining(mockDurationOverviewChartPlottableData));
      });
    });
  });
});
