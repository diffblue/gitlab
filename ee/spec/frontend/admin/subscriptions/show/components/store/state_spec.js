import createState from 'ee/admin/subscriptions/show/store/state';

describe('Admin Subscriptions Show State', () => {
  it('defaults to correct state', () => {
    const removePath = 'a/path/';
    const syncPath = 'another/path';

    expect(createState({ licenseRemovalPath: removePath, subscriptionSyncPath: syncPath })).toEqual(
      {
        subscriptionSyncStatus: null,
        breakdown: {
          hasAsyncActivity: false,
          licenseError: null,
          shouldShowNotifications: false,
        },
        paths: {
          licenseRemovalPath: removePath,
          subscriptionSyncPath: syncPath,
        },
      },
    );
  });
});
