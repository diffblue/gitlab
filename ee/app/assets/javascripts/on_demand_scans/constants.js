import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { stripTimezoneFromISODate } from '~/lib/utils/datetime/date_format_utility';

export const HELP_PAGE_PATH = helpPagePath('user/application_security/dast/index', {
  anchor: 'on-demand-scans',
});

export const HELP_PAGE_AUDITOR_ROLE_PATH = helpPagePath('administration/auditor_users.html', {
  anchor: 'auditor-users',
});

export const HELP_PAGE_RUNNER_TAGS_PATH = helpPagePath('ci/runners/configure_runners', {
  anchor: 'use-tags-to-control-which-jobs-a-runner-can-run',
});

export const LEARN_MORE_TEXT = s__(
  'OnDemandScans|%{learnMoreLinkStart}Learn more about on-demand scans%{learnMoreLinkEnd}.',
);
export const DAST_CONFIGURATION_HELP_PATH = helpPagePath('user/application_security/dast/index', {
  anchor: 'on-demand-scans',
});

export const PIPELINE_TABS_KEYS = ['all', 'running', 'finished', 'scheduled', 'saved'];
export const PIPELINES_PER_PAGE = 20;
export const PIPELINES_POLL_INTERVAL = 3000;
export const PIPELINES_COUNT_POLL_INTERVAL = 3000;
export const MAX_PIPELINES_COUNT = 1000;
export const MAX_DAST_PROFILES_COUNT = 100;

// Pipeline scopes
export const PIPELINES_SCOPE_RUNNING = 'RUNNING';
export const PIPELINES_SCOPE_FINISHED = 'FINISHED';

// Pipeline statuses
export const PIPELINES_GROUP_RUNNING = 'running';
export const PIPELINES_GROUP_PENDING = 'pending';
export const PIPELINES_GROUP_SUCCESS_WITH_WARNINGS = 'success-with-warnings';
export const PIPELINES_GROUP_FAILED = 'success-with-warnings';
export const PIPELINES_GROUP_SUCCESS = 'success';

// type of profiles
export const SCANNER_TYPE = 'scanner';
export const SITE_TYPE = 'site';

// dast sidebar mode
export const DRAWER_VIEW_MODE = {
  EDITING_MODE: 'editing_mode',
  READING_MODE: 'reading_mode',
};

const STATUS_COLUMN = {
  label: __('Status'),
  key: 'status',
  columnClass: 'gl-w-15',
};
const NAME_COLUMN = {
  label: __('Name'),
  key: 'name',
};
const SCAN_TYPE_COLUMN = {
  label: s__('OnDemandScans|Scan type'),
  key: 'scanType',
  columnClass: 'gl-w-13',
};
const TARGET_COLUMN = {
  label: s__('OnDemandScans|Target'),
  key: 'targetUrl',
};
const TARGET_COLUMN_DAST_PROFILE = {
  ...TARGET_COLUMN,
  formatter: (_value, _key, item) => item.dastSiteProfile.targetUrl,
};
const START_DATE_COLUMN = {
  label: __('Start date'),
  key: 'createdAt',
  columnClass: 'gl-w-15',
};
const PIPELINE_ID_COLUMN = {
  label: __('Pipeline'),
  key: 'id',
  columnClass: 'gl-w-15',
};
export const ACTION_COLUMN = {
  label: '',
  key: 'actions',
  columnClass: 'gl-w-20',
};

export const BASE_TABS_TABLE_FIELDS = [
  {
    ...STATUS_COLUMN,
    formatter: (_value, _key, item) => item.detailedStatus,
  },
  {
    ...NAME_COLUMN,
    formatter: (_value, _key, item) => item?.dastProfile?.name,
  },
  SCAN_TYPE_COLUMN,
  {
    ...TARGET_COLUMN,
    formatter: (_value, _key, item) => item?.dastProfile?.dastSiteProfile?.targetUrl,
  },
  START_DATE_COLUMN,
  PIPELINE_ID_COLUMN,
];

export const SCHEDULED_TAB_TABLE_FIELDS = [
  {
    ...STATUS_COLUMN,
    formatter: (_value, _key, item) => ({
      detailsPath: item.editPath,
      text: __('Scheduled'),
      icon: 'status_scheduled',
      group: 'scheduled',
    }),
  },
  NAME_COLUMN,
  SCAN_TYPE_COLUMN,
  TARGET_COLUMN_DAST_PROFILE,
  {
    label: __('Next scan'),
    key: 'nextRun',
    formatter: (_value, _key, item) => {
      const date = new Date(item.dastProfileSchedule.nextRunAt);
      const time = new Date(stripTimezoneFromISODate(item.dastProfileSchedule.startsAt));
      return {
        date: date.toLocaleDateString(window.navigator.language, {
          year: 'numeric',
          month: 'numeric',
          day: 'numeric',
        }),
        time: time.toLocaleTimeString(window.navigator.language, {
          hour: '2-digit',
          minute: '2-digit',
        }),
        timezone: item.dastProfileSchedule.timezone,
      };
    },
  },
  {
    label: s__('OnDemandScans|Repeats'),
    key: 'dastProfileSchedule',
  },
];

export const SAVED_TAB_TABLE_FIELDS = [
  NAME_COLUMN,
  TARGET_COLUMN_DAST_PROFILE,
  {
    label: s__('DastProfiles|Scan mode'),
    key: 'scanType',
    formatter: (_value, _key, item) => item.dastScannerProfile?.scanType,
  },
];

export const DAST_PROFILES_DRAWER = 'dast';
export const PRE_SCAN_VERIFICATION_DRAWER = 'verification';
