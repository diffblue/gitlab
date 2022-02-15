import { s__, __ } from '~/locale';

export const DEFAULT_POLLING_INTERVAL = 30000;
export const PER_PAGE = 20;
export const DEBOUNCE_DELAY = 500;
export const PROGRESS_BAR_HEIGHT = '8px';
export const DATE_TIME_FORMAT = 'yyyy-mm-dd HH:MM';
export const GROUP_DEVOPS_PATH = '/groups/%{fullPath}/-/analytics/devops_adoption';

export const OVERVIEW_TABLE_NAME_KEY = 'name';

export const TABLE_SORT_BY_STORAGE_KEY = 'devops_adoption_table_sort_by';
export const TABLE_SORT_DESC_STORAGE_KEY = 'devops_adoption_table_sort_desc';

export const OVERVIEW_TABLE_SORT_BY_STORAGE_KEY = 'devops_adoption_overview_table_sort_by';
export const OVERVIEW_TABLE_SORT_DESC_STORAGE_KEY = 'devops_adoption_overview_table_sort_desc';

export const TRACK_ADOPTION_TAB_CLICK_EVENT = 'i_analytics_dev_ops_adoption';
export const TRACK_DEVOPS_SCORE_TAB_CLICK_EVENT = 'i_analytics_dev_ops_score';

export const I18N_GROUPS_QUERY_ERROR = s__(
  'DevopsAdoption|There was an error fetching Groups. Please refresh the page.',
);
export const I18N_ENABLED_NAMESPACE_QUERY_ERROR = s__(
  'DevopsAdoption|There was an error fetching Group adoption data. Please refresh the page.',
);
export const I18N_ENABLE_NAMESPACE_MUTATION_ERROR = s__(
  'DevopsAdoption|There was an error enabling the current group. Please refresh the page.',
);

export const I18N_TABLE_REMOVE_BUTTON = s__('DevopsAdoption|Remove Group from the table.');
export const I18N_TABLE_REMOVE_BUTTON_DISABLED = s__(
  'DevopsAdoption|You cannot remove the group you are currently in.',
);

export const I18N_OVERVIEW_TABLE_HEADER_GROUP = s__('DevopsAdoption|Adoption by group');
export const I18N_OVERVIEW_TABLE_HEADER_SUBGROUP = s__('DevopsAdoption|Adoption by subgroup');

export const I18N_GROUP_DROPDOWN_TEXT = s__('DevopsAdoption|Add or remove subgroups');
export const I18N_GROUP_DROPDOWN_HEADER = s__('DevopsAdoption|Edit subgroups');
export const I18N_ADMIN_DROPDOWN_TEXT = s__('DevopsAdoption|Add or remove groups');
export const I18N_ADMIN_DROPDOWN_HEADER = s__('DevopsAdoption|Edit groups');

export const I18N_NO_RESULTS = s__('DevopsAdoption|No results…');
export const I18N_NO_SUB_GROUPS = s__('DevopsAdoption|This group has no subgroups');

export const I18N_FEATURES_ADOPTED_TEXT = s__(
  'DevopsAdoption|%{adoptedCount}/%{featuresCount} %{title} features adopted',
);

export const I18N_EMPTY_STATE_TITLE = s__('DevopsAdoption|Add a group to get started');
export const I18N_EMPTY_STATE_DESCRIPTION = s__(
  'DevopsAdoption|DevOps adoption tracks the use of key features across your favorite groups. Add a group to the table to begin.',
);

export const I18N_DELETE_MODAL_TITLE = s__('DevopsAdoption|Confirm remove Group');
export const I18N_DELETE_MODAL_CONFIRMATION_MESSAGE = s__(
  'DevopsAdoption|Are you sure that you would like to remove %{name} from the table?',
);
export const I18N_DELETE_MODAL_CANCEL = __('Cancel');
export const I18N_DELETE_MODAL_CONFIRM = s__('DevopsAdoption|Remove Group');
export const I18N_DELETE_MODAL_ERROR = s__(
  'DevopsAdoption|An error occurred while removing the group. Please try again.',
);

export const I18N_TABLE_HEADER_TEXT = s__(
  'DevopsAdoption|Feature adoption is based on usage in the previous calendar month. Data is updated at the beginning of each month. Last updated: %{timestamp}.',
);

export const I18N_CELL_FLAG_TRUE_TEXT = s__('DevopsAdoption|Adopted');
export const I18N_CELL_FLAG_FALSE_TEXT = s__('DevopsAdoption|Not adopted');

export const I18N_GROUP_COL_LABEL = __('Group');

export const I18N_OVERVIEW_CHART_TITLE = s__('DevopsAdoption|Adoption over time');
export const I18N_OVERVIEW_CHART_Y_AXIS_TITLE = s__(
  'DevopsAdoption|Total number of features adopted',
);
export const I18N_NO_FEATURE_META = s__('DevopsAdoption|No tracked features');

export const OVERVIEW_CHART_X_AXIS_TYPE = 'category';
export const OVERVIEW_CHART_Y_AXIS_TYPE = 'value';

export const OVERVIEW_CHART_PRESENTATION = 'tiled';

// $data-viz-orange-600, $data-viz-aqua-500, $data-viz-green-600
export const CUSTOM_PALETTE = ['#b24800', '#0094b6', '#487900'];

export const DEVOPS_ADOPTION_OVERALL_CONFIGURATION = {
  title: s__('DevopsAdoption|Overall adoption'),
  icon: 'tanuki',
  variant: 'primary',
  cols: [],
};

export const DEVOPS_ADOPTION_TABLE_CONFIGURATION = [
  {
    title: s__('DevopsAdoption|Dev'),
    key: 'dev',
    tab: 'dev',
    icon: 'code',
    variant: 'warning',
    testId: 'devCol',
    cols: [
      {
        key: 'mergeRequestApproved',
        label: s__('DevopsAdoption|Approvals'),
        tooltip: s__('DevopsAdoption|At least one approval on a merge request'),
        testId: 'approvalsCol',
      },
      {
        key: 'codeOwnersUsedCount',
        label: s__('DevopsAdoption|Code owners'),
        tooltip: s__('DevopsAdoption|Code owners enabled for at least one project'),
        testId: 'codeownersCol',
      },
      {
        key: 'issueOpened',
        label: s__('DevopsAdoption|Issues'),
        tooltip: s__('DevopsAdoption|At least one issue created'),
        testId: 'issuesCol',
      },
      {
        key: 'mergeRequestOpened',
        label: s__('DevopsAdoption|MRs'),
        tooltip: s__('DevopsAdoption|At least one merge request created'),
        testId: 'mrsCol',
      },
    ],
  },
  {
    title: s__('DevopsAdoption|Sec'),
    tab: 'sec',
    key: 'sec',
    icon: 'shield',
    variant: 'info',
    testId: 'secCol',
    cols: [
      {
        key: 'dastEnabledCount',
        label: s__('DevopsAdoption|DAST'),
        tooltip: s__('DevopsAdoption|DAST enabled for at least one project'),
      },
      {
        key: 'dependencyScanningEnabledCount',
        label: s__('DevopsAdoption|Dependency Scanning'),
        tooltip: s__('DevopsAdoption|Dependency Scanning enabled for at least one project'),
      },
      {
        key: 'coverageFuzzingEnabledCount',
        label: s__('DevopsAdoption|Fuzz Testing'),
        tooltip: s__('DevopsAdoption|Fuzz Testing enabled for at least one project'),
      },
      {
        key: 'sastEnabledCount',
        label: s__('DevopsAdoption|SAST'),
        tooltip: s__('DevopsAdoption|SAST enabled for at least one project'),
      },
    ],
  },
  {
    title: s__('DevopsAdoption|Ops'),
    tab: 'ops',
    key: 'ops',
    icon: 'rocket',
    variant: 'success',
    testId: 'opsCol',
    cols: [
      {
        key: 'deploySucceeded',
        label: s__('DevopsAdoption|Deploys'),
        tooltip: s__('DevopsAdoption|At least one deploy'),
      },
      {
        key: 'pipelineSucceeded',
        label: s__('DevopsAdoption|Pipelines'),
        tooltip: s__('DevopsAdoption|At least one pipeline successfully run'),
      },
      {
        key: 'runnerConfigured',
        label: s__('DevopsAdoption|Runners'),
        tooltip: s__('DevopsAdoption|Runner configured for project/group'),
      },
    ],
  },
];
