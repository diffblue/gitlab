import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const FILTER_STATES = {
  ALL: {
    label: __('All'),
    value: '',
  },
  STARTED: {
    label: __('Started'),
    value: 'started',
  },
  PENDING: {
    label: __('In progress'),
    value: 'pending',
  },
  SYNCED: {
    label: __('Synced'),
    value: 'synced',
  },
  FAILED: {
    label: __('Failed'),
    value: 'failed',
  },
};

export const FILTER_OPTIONS = Object.values(FILTER_STATES);

export const DEFAULT_STATUS = 'never';

export const STATUS_ICON_NAMES = {
  [FILTER_STATES.STARTED.value]: 'clock',
  [FILTER_STATES.SYNCED.value]: 'check-circle-filled',
  [FILTER_STATES.PENDING.value]: 'status_pending',
  [FILTER_STATES.FAILED.value]: 'status_failed',
  [DEFAULT_STATUS]: 'status_notfound',
};

export const STATUS_ICON_CLASS = {
  [FILTER_STATES.STARTED.value]: 'gl-text-orange-500',
  [FILTER_STATES.SYNCED.value]: 'gl-text-green-500',
  [FILTER_STATES.PENDING.value]: 'gl-text-orange-500',
  [FILTER_STATES.FAILED.value]: 'gl-text-red-500',
  [DEFAULT_STATUS]: 'gl-text-gray-500',
};

export const DEFAULT_SEARCH_DELAY = 500;

export const ACTION_TYPES = {
  RESYNC: 'resync',
  REVERIFY: 'reverify',
};

export const PREV = 'prev';

export const NEXT = 'next';

export const DEFAULT_PAGE_SIZE = 20;

export const RESYNC_MODAL_ID = 'resync-all-geo';

export const GEO_TROUBLESHOOTING_LINK = helpPagePath(
  'administration/geo/replication/troubleshooting.md',
);
