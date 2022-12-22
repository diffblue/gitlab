export default ({ licenseRemovalPath, subscriptionSyncPath, hasAsyncActivity = false }) => ({
  subscriptionSyncStatus: null,
  breakdown: {
    shouldShowNotifications: false,
    hasAsyncActivity,
    licenseError: null,
  },
  paths: Object.freeze({
    licenseRemovalPath,
    subscriptionSyncPath,
  }),
});
