import {
  subscriptionTypes,
  offlineCloudLicenseText,
  onlineCloudLicenseText,
  licenseFileText,
} from './constants';

export const getLicenseFromData = ({ data } = {}) => data?.gitlabSubscriptionActivate?.license;
export const getErrorsAsData = ({ data } = {}) => data?.gitlabSubscriptionActivate?.errors || [];

export function getLicenseTypeLabel(type) {
  switch (type) {
    case subscriptionTypes.OFFLINE_CLOUD:
      return offlineCloudLicenseText;
    case subscriptionTypes.ONLINE_CLOUD:
      return onlineCloudLicenseText;
    default:
      return licenseFileText;
  }
}
