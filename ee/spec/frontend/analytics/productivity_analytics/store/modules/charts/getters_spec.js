import { HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import {
  metricTypes,
  chartKeys,
  columnHighlightStyle,
  scatterPlotAddonQueryDays,
} from 'ee/analytics/productivity_analytics/constants';
import * as getters from 'ee/analytics/productivity_analytics/store/modules/charts/getters';
import createState from 'ee/analytics/productivity_analytics/store/modules/charts/state';
import { getScatterPlotData, getMedianLineData } from 'ee/analytics/productivity_analytics/utils';

jest.mock('ee/analytics/productivity_analytics/utils');

describe('Productivity analytics chart getters', () => {
  let state;

  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';
  const transformedData = [
    [{ merged_at: '2019-09-01T00:00:000Z', metric: 10 }],
    [{ merged_at: '2019-09-02T00:00:000Z', metric: 20 }],
  ];

  beforeEach(() => {
    state = createState();
  });

  describe('chartLoading', () => {
    it('returns true', () => {
      state.charts[chartKeys.main].isLoading = true;

      const result = getters.chartLoading(state)(chartKeys.main);

      expect(result).toBe(true);
    });
  });

  describe('getColumnChartData', () => {
    it("parses the column chart's data and adds a color property to selected items", () => {
      const chartKey = chartKeys.main;
      state.charts[chartKey] = {
        data: {
          1: 32,
          5: 17,
        },
        selected: ['5'],
      };

      const chartData = [
        { value: ['1', 32], itemStyle: {} },
        { value: ['5', 17], itemStyle: columnHighlightStyle },
      ];

      expect(getters.getColumnChartData(state)(chartKey)).toEqual(chartData);
    });
  });

  describe('getScatterPlotMainData', () => {
    it('calls getScatterPlotData with the raw scatterplot data and the date in past', () => {
      state.charts.scatterplot.transformedData = transformedData;

      const rootState = {
        filters: {
          startDate: '2019-09-01',
          endDate: '2019-09-05',
        },
      };

      getters.getScatterPlotMainData(state, null, rootState);

      expect(getScatterPlotData).toHaveBeenCalledWith(
        transformedData,
        new Date(rootState.filters.startDate),
        new Date(rootState.filters.endDate),
      );
    });
  });

  describe('getScatterPlotMedianData', () => {
    it('calls getMedianLineData with the raw scatterplot data, the getScatterPlotMainData getter and the an additional days offset', () => {
      state.charts.scatterplot.transformedData = transformedData;

      const rootState = {
        filters: {
          startDate: '2019-09-01',
          endDate: '2019-09-05',
        },
      };

      getters.getScatterPlotMedianData(state, null, rootState);

      expect(getMedianLineData).toHaveBeenCalledWith(
        transformedData,
        new Date(rootState.filters.startDate),
        new Date(rootState.filters.endDate),
        scatterPlotAddonQueryDays,
      );
    });
  });

  describe('getMetricLabel', () => {
    it('returns the correct label for the "time_to_last_commit" metric', () => {
      state.charts[chartKeys.timeBasedHistogram].params = {
        metricType: 'time_to_last_commit',
      };

      expect(getters.getMetricLabel(state)(chartKeys.timeBasedHistogram)).toBe(
        'Time from first comment to last commit',
      );
    });
  });

  describe('getFilterParams', () => {
    const rootGetters = {};

    rootGetters['filters/getCommonFilterParams'] = () => {
      const params = {
        group_id: groupNamespace,
        project_id: projectPath,
      };
      return params;
    };

    describe('main chart', () => {
      it('returns the correct params object', () => {
        const expected = {
          group_id: groupNamespace,
          project_id: projectPath,
          chart_type: state.charts[chartKeys.main].params.chartType,
        };

        expect(getters.getFilterParams(state, null, null, rootGetters)(chartKeys.main)).toEqual(
          expected,
        );
      });
    });

    describe('timeBasedHistogram charts', () => {
      const chartKey = chartKeys.timeBasedHistogram;

      describe('main chart has selected items', () => {
        it('returns the params object including "days_to_merge"', () => {
          state.charts = {
            [chartKeys.main]: {
              selected: ['5'],
            },
            [chartKeys.timeBasedHistogram]: {
              params: {
                chartType: 'histogram',
              },
            },
          };

          const expected = {
            group_id: groupNamespace,
            project_id: projectPath,
            chart_type: state.charts[chartKey].params.chartType,
            days_to_merge: ['5'],
          };

          expect(getters.getFilterParams(state, null, null, rootGetters)(chartKey)).toEqual(
            expected,
          );
        });
      });

      describe('chart has a metricType', () => {
        it('returns the params object including metric_type', () => {
          state.charts = {
            [chartKeys.main]: {
              selected: [],
            },
            [chartKeys.timeBasedHistogram]: {
              params: {
                chartType: 'histogram',
                metricType: 'time_to_first_comment',
              },
            },
          };

          const expected = {
            group_id: groupNamespace,
            project_id: projectPath,
            chart_type: state.charts[chartKey].params.chartType,
            days_to_merge: [],
            metric_type: 'time_to_first_comment',
          };

          expect(getters.getFilterParams(state, null, null, rootGetters)(chartKey)).toEqual(
            expected,
          );
        });
      });
    });
  });

  describe('getSelectedMetric', () => {
    it('returns the currently selected metric for a given chartKey', () => {
      const metricType = 'time_to_last_commit';
      state.charts[chartKeys.timeBasedHistogram].params = {
        metricType,
      };

      expect(getters.getSelectedMetric(state)(chartKeys.timeBasedHistogram)).toBe(
        'time_to_last_commit',
      );
    });
  });

  describe('scatterplotYaxisLabel', () => {
    const metricsInHours = ['time_to_first_comment', 'time_to_last_commit', 'time_to_merge'];

    const mockRootState = {
      metricTypes,
    };

    it('returns "Days" for "days_to_merge" metric', () => {
      const mockGetters = {
        getSelectedMetric: () => 'days_to_merge',
      };
      expect(getters.scatterplotYaxisLabel(null, mockGetters, mockRootState)).toBe('Days');
    });

    it.each(metricsInHours)('returns "Hours" for the "%s" metric', (metric) => {
      const mockGetters = {
        getSelectedMetric: () => metric,
      };
      expect(getters.scatterplotYaxisLabel(null, mockGetters, mockRootState)).toBe('Hours');
    });

    it.each`
      metric              | label
      ${'commits_count'}  | ${'Number of commits per MR'}
      ${'loc_per_commit'} | ${'Number of LOCs per commit'}
      ${'files_touched'}  | ${'Number of files touched'}
    `('calls getMetricLabel for the "$metric" metric', ({ metric }) => {
      const mockGetters = {
        getSelectedMetric: () => metric,
        getMetricLabel: jest.fn(),
      };

      getters.scatterplotYaxisLabel(null, mockGetters, mockRootState);

      expect(mockGetters.getMetricLabel).toHaveBeenCalled();
    });
  });

  describe('hasNoAccessError', () => {
    it('returns true if errorCode is set to 403', () => {
      state.charts[chartKeys.main].errorCode = HTTP_STATUS_FORBIDDEN;
      expect(getters.hasNoAccessError(state)).toEqual(true);
    });

    it('returns false if errorCode is not set to 403', () => {
      state.charts[chartKeys.main].errorCode = null;
      expect(getters.hasNoAccessError(state)).toEqual(false);
    });
  });

  describe('isChartEnabled', () => {
    const chartKey = chartKeys.scatterplot;
    it('returns true if the chart is enabled', () => {
      state.charts[chartKey].enabled = true;
      expect(getters.isChartEnabled(state)(chartKey)).toBe(true);
    });

    it('returns false if the chart is disabled', () => {
      state.charts[chartKey].enabled = false;
      expect(getters.isChartEnabled(state)(chartKey)).toBe(false);
    });
  });

  describe('isFilteringByDaysToMerge', () => {
    it('returns true if there are items selected on the main chart', () => {
      state.charts[chartKeys.main].selected = [1, 2];
      expect(getters.isFilteringByDaysToMerge(state)).toBe(true);
    });

    it('returns false if there are no items selected on the main chart', () => {
      state.charts[chartKeys.main].selected = [];
      expect(getters.isFilteringByDaysToMerge(state)).toBe(false);
    });
  });
});
