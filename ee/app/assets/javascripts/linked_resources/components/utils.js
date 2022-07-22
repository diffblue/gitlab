import { createAlert } from '~/flash';

export const displayAndLogError = (message, captureError, error) =>
  createAlert({
    message,
    captureError,
    error,
  });

const LINK_TYPE_ICON_MAP = {
  general: 'external-link',
  zoom: 'brand-zoom',
};

export const getLinkIcon = (type) => {
  return LINK_TYPE_ICON_MAP[type] ?? LINK_TYPE_ICON_MAP.general;
};
