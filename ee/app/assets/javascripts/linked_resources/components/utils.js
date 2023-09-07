import { s__ } from '~/locale';
import { createAlert } from '~/alert';

const zoomRegex = /(https:\/\/(?:[\w-]+\.)?zoom\.us\/(?:s|j|my)\/\S+)/;
const slackRegex = /(https:\/\/[a-zA-Z0-9]+.slack\.com\/[a-z\][a-zA-Z0-9_]+)/;
const pagerdutyRegex = /(https:\/\/[a-zA-Z0-9]+.pagerduty\.com\/incidents\/[a-z\][a-zA-Z0-9]+)/;

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

export const identifyLinkType = (link) => {
  if (zoomRegex.test(link)) {
    return 'zoom';
  }
  if (slackRegex.test(link)) {
    return 'slack';
  }
  if (pagerdutyRegex.test(link)) {
    return 'pagerduty';
  }
  return 'general';
};
