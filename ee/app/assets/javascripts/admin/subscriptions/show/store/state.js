export default ({ licenseRemovalPath, subscriptionSyncPath }) => ({
  subscriptionSyncStatus: null,
  breakdown: {
    shouldShowNotifications: false,
    hasAsyncActivity: false,
    licenseError: null,
  },
  paths: Object.freeze({
    licenseRemovalPath,
    subscriptionSyncPath,
  }),
});
