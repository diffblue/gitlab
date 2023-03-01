import { __, s__ } from '~/locale';

export const chartKeys = {
  main: 'main',
  timeBasedHistogram: 'timeBasedHistogram',
  commitBasedHistogram: 'commitBasedHistogram',
  scatterplot: 'scatterplot',
};

export const chartTypes = {
  histogram: 'histogram',
  scatterplot: 'scatterplot',
};

export const metricTypes = [
  {
    key: 'days_to_merge',
    label: __('Days to merge'),
    charts: [chartKeys.scatterplot],
  },
  {
    key: 'time_to_first_comment',
    label: __('Time from first commit until first comment'),
    charts: [chartKeys.timeBasedHistogram, chartKeys.scatterplot],
  },
  {
    key: 'time_to_last_commit',
    label: __('Time from first comment to last commit'),
    charts: [chartKeys.timeBasedHistogram, chartKeys.scatterplot],
  },
  {
    key: 'time_to_merge',
    label: __('Time from last commit to merge'),
    charts: [chartKeys.timeBasedHistogram, chartKeys.scatterplot],
  },
  {
    key: 'commits_count',
    label: __('Number of commits per MR'),
    charts: [chartKeys.commitBasedHistogram, chartKeys.scatterplot],
  },
  {
    key: 'loc_per_commit',
    label: __('Number of LOCs per commit'),
    charts: [chartKeys.commitBasedHistogram, chartKeys.scatterplot],
  },
  {
    key: 'files_touched',
    label: __('Number of files touched'),
    charts: [chartKeys.commitBasedHistogram, chartKeys.scatterplot],
  },
];

export const tableSortOrder = {
  asc: {
    title: s__('ProductivityAnalytics|Ascending'),
    value: 'asc',
    icon: 'sort-lowest',
  },
  desc: {
    title: s__('ProductivityAnalytics|Descending'),
    value: 'desc',
    icon: 'sort-highest',
  },
};

export const daysToMergeMetric = {
  key: 'days_to_merge',
  label: s__('ProductivityAnalytics|Days to merge'),
};

export const defaultMaxColumnChartItemsPerPage = 20;
export const maxColumnChartItemsPerPage = {
  [chartKeys.main]: 40,
};
/**
 * #418cd8 --> $blue-400 (see variables.scss)
 */
export const columnHighlightStyle = { color: '#418cd8', opacity: 0.8 };

// The number of days which will be to the state's daysInPast
// This is required to query historical data from the API to draw a 30 days rolling median line
export const scatterPlotAddonQueryDays = 30;

export const accessLevelReporter = 20;
export const projectsPerPage = 50;
