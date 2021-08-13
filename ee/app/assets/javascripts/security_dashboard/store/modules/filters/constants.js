import { s__ } from '~/locale';

export const ALL = 'all';
export const STATE = {
  DETECTED: 'DETECTED',
  CONFIRMED: 'CONFIRMED',
};
export const DISMISSAL_STATES = {
  DISMISSED: 'dismissed',
  ALL: 'all',
};

export const BASE_FILTERS = {
  state: {
    name: s__('VulnerabilityStatusTypes|All statuses'),
    id: ALL,
  },
  severity: {
    name: s__('ciReport|All severities'),
    id: ALL,
  },
  report_type: {
    name: s__('ciReport|All tools'),
    id: ALL,
  },
  activity: {
    name: s__('SecurityReports|All activity'),
    id: ALL,
  },
  project_id: {
    name: s__('ciReport|All projects'),
    id: ALL,
  },
};
