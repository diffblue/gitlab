import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

export const GEO_INFO_URL = helpPagePath('administration/geo/index.md');

export const HELP_SITE_HEALTH_URL = helpPagePath(
  'administration/geo/replication/troubleshooting.html',
  { anchor: 'check-the-health-of-the-secondary-site' },
);

export const GEO_TROUBLESHOOTING_URL = helpPagePath(
  'administration/geo/replication/troubleshooting.html',
);

export const HELP_INFO_URL = helpPagePath(
  'administration/geo/disaster_recovery/background_verification.html',
  { anchor: 'repository-verification' },
);

export const REPLICATION_PAUSE_URL = helpPagePath('administration/geo/index.html', {
  anchor: 'pausing-and-resuming-replication',
});

export const GEO_REPLICATION_SUPPORTED_TYPES_URL = helpPagePath(
  'administration/geo/replication/datatypes.html',
  { anchor: 'data-types' },
);

export const HEALTH_STATUS_UI = {
  healthy: {
    icon: 'status_success',
    variant: 'success',
    text: s__('Geo|Healthy'),
  },
  unhealthy: {
    icon: 'status_failed',
    variant: 'danger',
    text: s__('Geo|Unhealthy'),
  },
  disabled: {
    icon: 'status_canceled',
    variant: 'neutral',
    text: s__('Geo|Disabled'),
  },
  unknown: {
    icon: 'status_notfound',
    variant: 'neutral',
    text: s__('Geo|Unknown'),
  },
  offline: {
    icon: 'status_canceled',
    variant: 'neutral',
    text: s__('Geo|Offline'),
  },
};

export const REPLICATION_STATUS_UI = {
  enabled: {
    color: 'gl-text-green-600',
    text: __('Enabled'),
  },
  disabled: {
    color: 'gl-text-orange-600',
    text: __('Paused'),
  },
};

export const STATUS_DELAY_THRESHOLD_MS = 600000;

export const REMOVE_SITE_MODAL_ID = 'remove-site-modal';

export const STATUS_FILTER_QUERY_PARAM = 'status';
