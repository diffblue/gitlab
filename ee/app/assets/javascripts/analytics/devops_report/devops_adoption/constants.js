import { s__, __ } from '~/locale';

export const DEFAULT_POLLING_INTERVAL = 30000;
export const PER_PAGE = 20;
export const DEBOUNCE_DELAY = 500;
export const PROGRESS_BAR_HEIGHT = '8px';
export const DATE_TIME_FORMAT = 'yyyy-mm-dd HH:MM';
export const DELETE_MODAL_ID = 'devopsDeleteModal';

export const TABLE_TEST_IDS_HEADERS = 'header';
export const TABLE_TEST_IDS_NAMESPACE = 'namespaceCol';
export const TABLE_TEST_IDS_ACTIONS = 'actionsCol';
export const TABLE_TEST_IDS_LOCAL_STORAGE_SORT_BY = 'localStorageSortBy';
export const TABLE_TEST_IDS_LOCAL_STORAGE_SORT_DESC = 'localStorageSortDesc';

export const TABLE_SORT_BY_STORAGE_KEY = 'devops_adoption_table_sort_by';
export const TABLE_SORT_DESC_STORAGE_KEY = 'devops_adoption_table_sort_desc';

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

export const I18N_GROUP_DROPDOWN_TEXT = s__('DevopsAdoption|Add sub-group to table');
export const I18N_GROUP_DROPDOWN_HEADER = s__('DevopsAdoption|Add sub-group');
export const I18N_ADMIN_DROPDOWN_TEXT = s__('DevopsAdoption|Add group to table');
export const I18N_ADMIN_DROPDOWN_HEADER = s__('DevopsAdoption|Add group');

export const I18N_NO_RESULTS = s__('DevopsAdoption|No results…');
export const I18N_NO_SUB_GROUPS = s__('DevopsAdoption|This group has no sub-groups');

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
  'DevopsAdoption|Feature adoption is based on usage in the previous calendar month. Last updated: %{timestamp}.',
);

export const I18N_CELL_FLAG_TRUE_TEXT = s__('DevopsAdoption|Adopted');
export const I18N_CELL_FLAG_FALSE_TEXT = s__('DevopsAdoption|Not adopted');

export const I18N_GROUP_COL_LABEL = __('Group');

export const DEVOPS_ADOPTION_OVERALL_CONFIGURATION = {
  title: s__('DevopsAdoption|Overall adoption'),
  icon: 'tanuki',
  variant: 'primary',
  cols: [],
};

export const DEVOPS_ADOPTION_TABLE_CONFIGURATION = [
  {
    title: s__('DevopsAdoption|Dev'),
    tab: 'dev',
    icon: 'code',
    variant: 'warning',
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
        tooltip: s__('DevopsAdoption|At least one issue opened'),
        testId: 'issuesCol',
      },
      {
        key: 'mergeRequestOpened',
        label: s__('DevopsAdoption|MRs'),
        tooltip: s__('DevopsAdoption|At least one merge request opened'),
        testId: 'mrsCol',
      },
    ],
  },
  {
    title: s__('DevopsAdoption|Sec'),
    tab: 'sec',
    icon: 'shield',
    variant: 'info',
    cols: [
      {
        key: 'dastEnabledCount',
        label: s__('DevopsAdoption|DAST'),
        tooltip: s__('DevopsAdoption|DAST enabled for at least one project'),
        testId: 'dastCol',
      },
      {
        key: 'sastEnabledCount',
        label: s__('DevopsAdoption|SAST'),
        tooltip: s__('DevopsAdoption|SAST enabled for at least one project'),
        testId: 'sastCol',
      },
    ],
  },
  {
    title: s__('DevopsAdoption|Ops'),
    tab: 'ops',
    icon: 'rocket',
    variant: 'success',
    cols: [
      {
        key: 'deploySucceeded',
        label: s__('DevopsAdoption|Deploys'),
        tooltip: s__('DevopsAdoption|At least one deploy'),
        testId: 'deploysCol',
      },
      {
        key: 'pipelineSucceeded',
        label: s__('DevopsAdoption|Pipelines'),
        tooltip: s__('DevopsAdoption|At least one pipeline successfully run'),
        testId: 'pipelinesCol',
      },
      {
        key: 'runnerConfigured',
        label: s__('DevopsAdoption|Runners'),
        tooltip: s__('DevopsAdoption|Runner configured for project/group'),
        testId: 'runnersCol',
      },
    ],
  },
];
