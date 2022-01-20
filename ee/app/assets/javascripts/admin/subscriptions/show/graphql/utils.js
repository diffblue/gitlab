import produce from 'immer';
import getCurrentLicense from './queries/get_current_license.query.graphql';
import getLicenseHistory from './queries/get_license_history.query.graphql';

export const getLicenseFromData = ({ data } = {}) => data?.gitlabSubscriptionActivate?.license;
export const getErrorsAsData = ({ data } = {}) => data?.gitlabSubscriptionActivate?.errors || [];

export const updateSubscriptionAppCache = (cache, mutation) => {
  const license = getLicenseFromData(mutation);
  if (!license) {
    return;
  }
  const data = produce({}, (draftData) => {
    draftData.currentLicense = license;
  });
  cache.writeQuery({ query: getCurrentLicense, data });
  const subscriptionsList = cache.readQuery({ query: getLicenseHistory });
  const subscriptionListData = produce(subscriptionsList, (draftData) => {
    draftData.licenseHistoryEntries.nodes = [
      license,
      ...subscriptionsList.licenseHistoryEntries.nodes,
    ];
  });
  cache.writeQuery({ query: getLicenseHistory, data: subscriptionListData });
};
