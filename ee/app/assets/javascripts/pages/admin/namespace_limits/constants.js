import { s__, __ } from '~/locale';

export const LIST_EXCLUSIONS_ENDPOINT = '/api/:version/namespaces/storage/limit_exclusions';
export const DELETE_EXCLUSION_ENDPOINT = '/api/:version/namespaces/:id/storage/limit_exclusion';

export const exclusionListFetchError = s__(
  'NamespaceLimits|There was an error fetching the exclusion list, try refreshing the page.',
);

export const excludedNamespacesDescription = s__(
  "NamespaceLimits|These namespaces won't receive any notifications nor any degraded functionality while they remain on this list",
);

export const exclusionDeleteError = s__(
  'NamespaceLimits|There was an error deleting the namespace, try again after refreshing the page.',
);

export const deleteModalTitle = s__('NamespaceLimits|Deletion confirmation');

export const deleteModalBody = s__(
  'NamespaceLimits|Do you confirm the deletion of the selected namespace?',
);

export const deleteModalProps = {
  primaryProps: {
    text: s__('NamespaceLimits|Confirm deletion'),
    attributes: { variant: 'danger', category: 'primary' },
  },
  cancelProps: { text: __('Cancel') },
};
