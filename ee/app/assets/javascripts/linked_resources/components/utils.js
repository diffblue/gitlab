import { s__ } from '~/locale';
import { createAlert } from '~/flash';

export const displayAndLogError = (error) =>
  createAlert({
    message: s__(
      'LinkedResources|Something went wrong while fetching linked resources for the incident.',
    ),
    captureError: true,
    error,
  });

const LINK_TYPE_ICON_MAP = {
  general: 'external-link',
  zoom: 'brand-zoom',
};

export const getLinkIcon = (type) => {
  return LINK_TYPE_ICON_MAP[type] ?? LINK_TYPE_ICON_MAP.general;
};
