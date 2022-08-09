import { CHART_TYPES } from 'ee/insights/constants';
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
      return s__('DORA4Metrics|Change failure rate (%%)');
    default:
      return '';
  }
};

export const transformChartDataForGlCharts = (
  { type, query: queryParams },
  { labels, datasets },
) => {
  const formattedData = {
    xAxisTitle: getAxisTitle(getGroupByValue(queryParams)),
    yAxisTitle: getAxisTitle(getTypeValue(queryParams)),
    labels,
    datasets: [],
    seriesNames: [],
  };

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
      formattedData.datasets.push(
        ...datasets.map((dataset) => ({
          name: dataset.label,
          data: labels.map((label, i) => [label, dataset.data[i]]),
        })),
      );

      break;
    default:
      formattedData.datasets = { all: labels.map((label, i) => [label, datasets[0].data[i]]) };
  }
  return formattedData;
};

export default {
  transformChartDataForGlCharts,
};
