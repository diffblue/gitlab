import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import { __, s__ } from '~/locale';

export const ERROR_RUN_SCAN = 'ERROR_RUN_SCAN';
export const ERROR_FETCH_SCANNER_PROFILES = 'ERROR_FETCH_SCANNER_PROFILES';
export const ERROR_FETCH_SITE_PROFILES = 'ERROR_FETCH_SITE_PROFILES';
export const ERROR_FETCH_RUNNER_TAGS = 'ERROR_FETCH_RUNNER_TAGS';

export const ERROR_MESSAGES = {
  [ERROR_RUN_SCAN]: s__('OnDemandScans|Could not run the scan. Please try again.'),
  [ERROR_FETCH_SCANNER_PROFILES]: s__(
    'OnDemandScans|Could not fetch scanner profiles. Please refresh the page, or try again later.',
  ),
  [ERROR_FETCH_SITE_PROFILES]: s__(
    'OnDemandScans|Could not fetch site profiles. Please refresh the page, or try again later.',
  ),
  [ERROR_FETCH_RUNNER_TAGS]: s__(
    'OnDemandScans|Unable to fetch runner tags. Try reloading the page.',
  ),
};

export const SCANNER_PROFILES_QUERY = {
  field: 'dastScannerProfileId',
  fetchQuery: dastScannerProfilesQuery,
  fetchError: ERROR_FETCH_SCANNER_PROFILES,
};

export const SITE_PROFILES_QUERY = {
  field: 'dastSiteProfileId',
  fetchQuery: dastSiteProfilesQuery,
  fetchError: ERROR_FETCH_SITE_PROFILES,
};

/* eslint-disable @gitlab/require-i18n-strings */
const DAY_1 = 'DAY_1';
const WEEK_1 = 'WEEK_1';
const MONTH_1 = 'MONTH_1';
const MONTH_3 = 'MONTH_3';
const MONTH_6 = 'MONTH_6';
const YEAR_1 = 'YEAR_1';
/* eslint-enable @gitlab/require-i18n-strings */

export const SCAN_CADENCE_OPTIONS = [
  { value: '', text: __('Never') },
  {
    value: DAY_1,
    text: __('Every day'),
    description: {
      text: __('Every day at %{time} %{timezone}'),
    },
  },
  {
    value: WEEK_1,
    text: __('Every week'),
    description: {
      text: __('Every week on %{day} at %{time} %{timezone}'),
      dayFormat: { weekday: 'long' },
    },
  },
  {
    value: MONTH_1,
    text: __('Every month'),
    description: {
      text: __('Every month on the %{day} at %{time} %{timezone}'),
      dayFormat: { day: 'numeric' },
    },
  },
  {
    value: MONTH_3,
    text: __('Every 3 months'),
    description: {
      text: __('Every 3 months on the %{day} at %{time} %{timezone}'),
      dayFormat: { day: 'numeric' },
    },
  },
  {
    value: MONTH_6,
    text: __('Every 6 months'),
    description: {
      text: __('Every 6 months on the %{day} at %{time} %{timezone}'),
      dayFormat: { day: 'numeric' },
    },
  },
  {
    value: YEAR_1,
    text: __('Every year'),
    description: {
      text: __('Every year on %{day} at %{time} %{timezone}'),
      dayFormat: { month: 'long', day: 'numeric' },
    },
  },
];

export const FROM_ONDEMAND_SCAN_ID_QUERY_PARAM = 'from_on_demand_scan_id';
