import { green400, orange400, red400, gray400 } from '@gitlab/ui/scss_to_js/scss_variables';
import { s__, __, n__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  FLOW_METRICS,
  DORA_METRICS,
  VULNERABILITY_METRICS,
  MERGE_REQUEST_METRICS,
} from '~/analytics/shared/constants';

export const MAX_PANELS_LIMIT = 4;

export const UNITS = {
  COUNT: 'COUNT',
  DAYS: 'DAYS',
  PER_DAY: 'PER_DAY',
  PERCENT: 'PERCENT',
};

export const TABLE_METRICS = {
  [DORA_METRICS.DEPLOYMENT_FREQUENCY]: {
    label: s__('DORA4Metrics|Deployment Frequency'),
    units: UNITS.PER_DAY,
  },
  [DORA_METRICS.LEAD_TIME_FOR_CHANGES]: {
    label: s__('DORA4Metrics|Lead Time for Changes'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [DORA_METRICS.TIME_TO_RESTORE_SERVICE]: {
    label: s__('DORA4Metrics|Time to Restore Service'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [DORA_METRICS.CHANGE_FAILURE_RATE]: {
    label: s__('DORA4Metrics|Change Failure Rate'),
    invertTrendColor: true,
    units: UNITS.PERCENT,
  },
  [FLOW_METRICS.LEAD_TIME]: {
    label: s__('DORA4Metrics|Lead time'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [FLOW_METRICS.CYCLE_TIME]: {
    label: s__('DORA4Metrics|Cycle time'),
    invertTrendColor: true,
    units: UNITS.DAYS,
  },
  [FLOW_METRICS.ISSUES]: {
    label: s__('DORA4Metrics|New issues'),
    units: UNITS.COUNT,
  },
  [FLOW_METRICS.ISSUES_COMPLETED]: {
    label: s__('DORA4Metrics|Closed issues'),
    units: UNITS.COUNT,
    valueLimit: {
      max: 10001,
      mask: '10000+',
      description: s__(
        'DORA4Metrics|This is a lower-bound approximation. Your group has too many issues and MRs to calculate in real time.',
      ),
    },
  },
  [FLOW_METRICS.DEPLOYS]: {
    label: s__('DORA4Metrics|Deploys'),
    units: UNITS.COUNT,
  },
  [MERGE_REQUEST_METRICS.THROUGHPUT]: {
    label: s__('DORA4Metrics|Merge request throughput'),
    units: UNITS.COUNT,
  },
  [VULNERABILITY_METRICS.CRITICAL]: {
    label: s__('DORA4Metrics|Critical Vulnerabilities over time'),
    invertTrendColor: true,
    units: UNITS.COUNT,
  },
  [VULNERABILITY_METRICS.HIGH]: {
    label: s__('DORA4Metrics|High Vulnerabilities over time'),
    invertTrendColor: true,
    units: UNITS.COUNT,
  },
};

export const METRICS_WITH_NO_TREND = [VULNERABILITY_METRICS.CRITICAL, VULNERABILITY_METRICS.HIGH];
export const METRICS_WITH_LABEL_FILTERING = [
  FLOW_METRICS.ISSUES,
  FLOW_METRICS.ISSUES_COMPLETED,
  FLOW_METRICS.CYCLE_TIME,
  FLOW_METRICS.LEAD_TIME,
  MERGE_REQUEST_METRICS.THROUGHPUT,
];
export const METRICS_WITHOUT_LABEL_FILTERING = Object.keys(TABLE_METRICS).filter(
  (metric) => !METRICS_WITH_LABEL_FILTERING.includes(metric),
);

export const DASHBOARD_TITLE = s__('DORA4Metrics|Value Streams Dashboard');
export const DASHBOARD_DESCRIPTION = s__(
  'DORA4Metrics|The Value Streams Dashboard allows all stakeholders from executives to individual contributors to identify trends, patterns, and opportunities for software development improvements.',
);
export const DASHBOARD_DOCS_LINK = helpPagePath('user/analytics/value_streams_dashboard');
export const DASHBOARD_DESCRIPTION_GROUP = s__('DORA4Metrics|Metrics comparison for %{name} group');
export const DASHBOARD_DESCRIPTION_PROJECT = s__(
  'DORA4Metrics|Metrics comparison for %{name} project',
);
export const DASHBOARD_LOADING_FAILURE = __('Failed to load');
export const DASHBOARD_NAMESPACE_LOAD_ERROR = s__(
  'DORA4Metrics|Failed to load comparison chart for Namespace: %{fullPath}',
);
export const DASHBOARD_LABELS_LOAD_ERROR = s__(
  'DORA4Metrics|Failed to load labels matching the filter: %{labels}',
);
export const VALUE_STREAMS_DASHBOARD_CONFIG = {
  title: DASHBOARD_TITLE,
  description: DASHBOARD_DESCRIPTION,
  slug: '/value_streams_dashboard',
  redirect: true,
  userDefined: false,
};

export const CHART_GRADIENT = ['#499767', '#5252B5'];
export const CHART_GRADIENT_INVERTED = [...CHART_GRADIENT].reverse();
export const CHART_LOADING_FAILURE = s__('DORA4Metrics|Failed to load charts');

export const CHART_TOOLTIP_UNITS = {
  [UNITS.COUNT]: undefined,
  [UNITS.DAYS]: __('days'),
  [UNITS.PER_DAY]: __('/day'),
  [UNITS.PERCENT]: '%',
};

export const YAML_CONFIG_PATH = '.gitlab/analytics/dashboards/value_streams/value_streams.yaml';
export const YAML_CONFIG_LOAD_ERROR = s__(
  'DORA4Metrics|Failed to load YAML config from Project: %{fullPath}',
);

export const CLICK_METRIC_DRILLDOWN_LINK_ACTION = 'click_link';

export const DORA_PERFORMERS_SCORE_CATEGORY_TYPES = {
  HIGH: 'highProjectsCount',
  MEDIUM: 'mediumProjectsCount',
  LOW: 'lowProjectsCount',
  NO_DATA: 'noDataProjectsCount',
};

export const DORA_PERFORMERS_SCORE_CATEGORIES = {
  [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.HIGH]: s__('DORA4Metrics|High'),
  [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.MEDIUM]: s__('DORA4Metrics|Medium'),
  [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.LOW]: s__('DORA4Metrics|Low'),
  [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.NO_DATA]: s__('DORA4Metrics|Not included'),
};

export const DORA_PERFORMERS_SCORE_METRICS = [
  // score definitions are listed in order from 'High' to 'Low' and accessed using the series index
  {
    label: s__('DORA4Metrics|Deployment Frequency (Velocity)'),
    scoreDefinitions: [
      s__('DORA4Metrics|Have 30 or more deploys to production per day.'),
      s__('DORA4Metrics|Have between 1 to 29 deploys to production per day.'),
      s__('DORA4Metrics|Have less than 1 deploy to production per day.'),
    ],
  },
  {
    label: s__('DORA4Metrics|Lead Time for Changes (Velocity)'),
    scoreDefinitions: [
      s__(
        'DORA4Metrics|Took 7 days or less to go from code committed to code successfully running in production.',
      ),
      s__(
        'DORA4Metrics|Took between 8 to 29 days to go from code committed to code successfully running in production.',
      ),
      s__(
        'DORA4Metrics|Took more than 30 days to go from code committed to code successfully running in production.',
      ),
    ],
  },
  {
    label: s__('DORA4Metrics|Time to Restore Service (Quality)'),
    scoreDefinitions: [
      s__(
        'DORA4Metrics|Took 1 day or less to restore service when a service incident or a defect that impacts users occurs.',
      ),
      s__(
        'DORA4Metrics|Took between 2 to 6 days to restore service when a service incident or a defect that impacts users occurs.',
      ),
      s__(
        'DORA4Metrics|Took more than 7 days to restore service when a service incident or a defect that impacts users occurs.',
      ),
    ],
  },
  {
    label: s__('DORA4Metrics|Change Failure Rate (Quality)'),
    scoreDefinitions: [
      sprintf(
        s__('DORA4Metrics|Made 15%% or less changes to production resulted in degraded service.'),
      ),
      sprintf(
        s__(
          'DORA4Metrics|Made between 16%% to 44%% of changes to production resulted in degraded service.',
        ),
      ),
      sprintf(
        s__(
          'DORA4Metrics|Made more than 45%% of changes to production resulted in degraded service.',
        ),
      ),
    ],
  },
];

export const DORA_PERFORMERS_SCORE_DEFAULT_PANEL_TITLE = s__(
  'DORA4Metrics|Total projects by DORA performers score',
);

export const DORA_PERFORMERS_SCORE_PANEL_TITLE_WITH_PROJECTS_COUNT = s__(
  'DORA4Metrics|Total projects (%{count}) by DORA performers score for %{groupName} group',
);

export const DORA_PERFORMERS_SCORE_TOOLTIP_PROJECTS_COUNT_TITLE = (count) =>
  n__('DORA4Metrics|%d project', 'DORA4Metrics|%d projects', count);

export const DORA_PERFORMERS_SCORE_NOT_INCLUDED = (count) =>
  n__('DORA4Metrics|Has no calculated data.', 'DORA4Metrics|Have no calculated data.', count);

export const DORA_PERFORMERS_SCORE_LOADING_ERROR = s__(
  'DORA4Metrics|Failed to load DORA performance scores for Namespace: %{fullPath}',
);

export const DORA_PERFORMERS_SCORE_PROJECT_NAMESPACE_ERROR = s__(
  'DORA4Metrics|This visualization is not supported for project namespaces.',
);

export const DORA_PERFORMERS_SCORE_NO_DATA = s__(
  'DORA4Metrics|No data available for Namespace: %{fullPath}',
);

export const DORA_PERFORMERS_SCORE_CHART_COLOR_PALETTE = [green400, orange400, red400, gray400];
