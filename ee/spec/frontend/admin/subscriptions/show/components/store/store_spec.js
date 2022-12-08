import createStore from 'ee/admin/subscriptions/show/store';
import createState from 'ee/admin/subscriptions/show/store/state';

describe('Admin Subscription Show Components store', () => {
  it('has a default state set', () => {
    const removePath = 'a/path/';
    const syncPath = 'another/path';

    const store = createStore({ licenseRemovalPath: removePath, subscriptionSyncPath: syncPath });
    expect(store.state).toStrictEqual(
      createState({ licenseRemovalPath: removePath, subscriptionSyncPath: syncPath }),
    );
  });
});
