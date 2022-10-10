import { pairDataAndLabels, buildNullSeries } from 'ee/analytics/shared/utils';
import { BASE_NULL_SERIES_OPTIONS, BASE_SERIES_DATA_OPTIONS } from 'ee/analytics/shared/constants';
import {
  CHART_TYPES,
  INSIGHTS_DATA_SOURCE_DORA,
  INSIGHTS_NO_DATA_TOOLTIP,
} from 'ee/insights/constants';
import { __, s__ } from '~/locale';

const getGroupByValue = (queryParams) => {
  return queryParams.group_by || queryParams.params.group_by;
};

const getTypeValue = (queryParams) => {
  return queryParams.issuable_type || queryParams.params.issuable_type || queryParams.params.metric;
};

const getAxisTitle = (label) => {
  switch (label) {
    case 'day':
      return __('Days');
    case 'week':
      return __('Weeks');
    case 'month':
      return __('Months');
    case 'issue':
      return __('Issues');
    case 'merge_request':
      return __('Merge requests');
    case 'deployment_frequency':
      return s__('DORA4Metrics|Deployment frequency');
    case 'lead_time_for_changes':
      return s__('DORA4Metrics|Lead time for changes (median days)');
    case 'time_to_restore_service':
      return s__('DORA4Metrics|Time to restore service (median days)');
    case 'change_failure_rate':
      return s__('DORA4Metrics|Change failure rate (percentage)');
    default:
      return '';
  }
};

export const transformChartDataForGlCharts = (
  { type, query: queryParams },
  { labels, datasets },
) => {
  const yAxisTitle = getAxisTitle(getTypeValue(queryParams));
  const formattedData = {
    xAxisTitle: getAxisTitle(getGroupByValue(queryParams)),
    yAxisTitle,
    labels,
    datasets: [],
    seriesNames: [],
  };

  const { data_source: dataSource = '' } = queryParams;

  switch (type) {
    case CHART_TYPES.BAR:
      formattedData.datasets = [
        {
          name: 'all',
          data: labels.map((label, i) => [label, datasets[0].data[i]]),
        },
      ];
      break;
    case CHART_TYPES.STACKED_BAR:
      formattedData.datasets.push(
        ...datasets.map((dataset) => ({
          name: dataset.label,
          data: dataset.data,
        })),
      );
      break;
    case CHART_TYPES.LINE:
      if (dataSource === INSIGHTS_DATA_SOURCE_DORA) {
        const paired = pairDataAndLabels({
          datasetNames: [yAxisTitle],
          axisLabels: labels,
          datasets,
        });

        formattedData.datasets = buildNullSeries({
          seriesData: paired,
          seriesDataOptions: BASE_SERIES_DATA_OPTIONS,
          nullSeriesTitle: INSIGHTS_NO_DATA_TOOLTIP,
          nullSeriesOptions: BASE_NULL_SERIES_OPTIONS,
        });
      } else {
        formattedData.datasets.push(
          ...datasets.map((dataset) => ({
            name: dataset.label,
            data: labels.map((label, i) => [label, dataset.data[i]]),
          })),
        );
      }
      break;
    default:
      formattedData.datasets = { all: labels.map((label, i) => [label, datasets[0].data[i]]) };
  }
  return formattedData;
};

export default {
  transformChartDataForGlCharts,
};
