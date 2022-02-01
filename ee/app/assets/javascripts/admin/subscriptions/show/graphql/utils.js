import produce from 'immer';
import getCurrentLicense from './queries/get_current_license.query.graphql';
import getPastLicenseHistory from './queries/get_past_license_history.query.graphql';

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
  const pastSubscriptions = cache.readQuery({ query: getPastLicenseHistory });
  const pastSubscriptionsData = produce(pastSubscriptions, (draftData) => {
    draftData.licenseHistoryEntries.nodes = [
      license,
      ...pastSubscriptions.licenseHistoryEntries.nodes,
    ];
  });
  cache.writeQuery({ query: getPastLicenseHistory, data: pastSubscriptionsData });
};
