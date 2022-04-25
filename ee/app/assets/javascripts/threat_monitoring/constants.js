import { __, s__ } from '~/locale';

export const DEFAULT_ASSIGNED_POLICY_PROJECT = { fullPath: '', branch: '' };

export const LOADING_TEXT = __('Loading...');

export const INVALID_CURRENT_ENVIRONMENT_NAME = '-';

export const ALL_ENVIRONMENT_NAME = s__('ThreatMonitoring|All Environments');

export const PAGE_SIZE = 20;

export const NAMESPACE_TYPES = {
  PROJECT: 'project',
  GROUP: 'group',
};
