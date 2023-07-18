import { s__, __ } from '~/locale';

export const APP_PLAN_LIMITS_ENDPOINT = '/api/:version/application/plan_limits';
export const LIST_EXCLUSIONS_ENDPOINT = '/api/:version/namespaces/storage/limit_exclusions';
export const DELETE_EXCLUSION_ENDPOINT = '/api/:version/namespaces/:id/storage/limit_exclusion';

export const APP_PLAN_LIMIT_PARAM_NAMES = {
  notifications: 'notification_limit',
  enforcement: 'enforcement_limit',
  dashboard: 'storage_size_limit',
};

export const exclusionListFetchError = s__(
  'NamespaceLimits|There was an error fetching the exclusion list, try refreshing the page.',
);

export const excludedNamespacesDescription = s__(
  "NamespaceLimits|These namespaces won't receive any notifications nor any degraded functionality while they remain on this list",
);

export const exclusionDeleteError = s__(
  'NamespaceLimits|There was an error deleting the namespace: "%{errorMessage}".',
);

export const deleteModalTitle = s__('NamespaceLimits|Deletion confirmation');

export const deleteModalBody = s__(
  'NamespaceLimits|Do you confirm the deletion of the selected namespace from the exclusion list?',
);

export const deleteModalProps = {
  primaryProps: {
    text: s__('NamespaceLimits|Confirm deletion'),
    attributes: { variant: 'danger', category: 'primary' },
  },
  cancelProps: { text: __('Cancel') },
};
