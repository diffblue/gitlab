import * as getters from 'ee/analytics/cycle_analytics/store/modules/duration_chart/getters';
import { createdAfter, createdBefore } from 'jest/cycle_analytics/mock_data';
import {
  transformedDurationData,
  durationChartPlottableData as mockDurationChartPlottableData,
} from '../../../mock_data';

const rootState = {
  createdAfter,
  createdBefore,
};

describe('DurationChart getters', () => {
  const [selectedStage] = transformedDurationData;
  const rootGetters = { isOverviewStageSelected: false };
  const selectedStageDurationData = [
    ['2019-01-01', 13, '2019-01-01'],
    ['2019-01-02', 27, '2019-01-02'],
  ];

  describe('durationChartPlottableData', () => {
    describe('with a VSA stage selected', () => {
      beforeEach(() => {
        rootState.selectedStage = selectedStage;
      });

      it('returns plottable data for the currently selected stage', () => {
        const stateWithDurationData = {
          durationData: transformedDurationData,
        };

        expect(
          getters.durationChartPlottableData(
            stateWithDurationData,
            getters,
            rootState,
            rootGetters,
          ),
        ).toEqual(selectedStageDurationData);
      });

      it('returns an empty array if there is no plottable data for the selected stages', () => {
        const stateWithDurationData = {
          durationData: [],
        };

        expect(
          getters.durationChartPlottableData(
            stateWithDurationData,
            getters,
            rootState,
            rootGetters,
          ),
        ).toEqual([]);
      });
    });
  });

  describe('with the overview stage selected', () => {
    beforeEach(() => {
      rootGetters.isOverviewStageSelected = true;
    });

    it('returns plottable data for all available stages', () => {
      const stateWithDurationData = {
        durationData: transformedDurationData,
        isOverviewStageSelected: true,
      };

      expect(
        getters.durationChartPlottableData(stateWithDurationData, getters, rootState, rootGetters),
      ).toEqual(mockDurationChartPlottableData);
    });
  });
});
