import mutations from 'ee/admin/subscriptions/show/store/mutations';
import * as types from 'ee/admin/subscriptions/show/store/mutation_types';
import state from 'ee/admin/subscriptions/show/store/state';

describe('Mutations', () => {
  let localState;

  beforeEach(() => {
    localState = state({ licenseRemovePath: '', subscriptionSyncPath: '' });
  });

  describe('Sync', () => {
    describe('REQUEST_SYNC', () => {
      const payload = 'anything';

      beforeEach(() => {
        mutations[types.REQUEST_SYNC](localState, payload);
      });

      it('updates subscriptionSyncStatus', () => {
        expect(localState.subscriptionSyncStatus).toBe(payload);
      });

      it('updates hasAsyncActivity', () => {
        expect(localState.breakdown.hasAsyncActivity).toBe(true);
      });
    });

    describe('RECEIVE_SYNC_ERROR', () => {
      const payload = 'anything';

      beforeEach(() => {
        mutations[types.RECEIVE_SYNC_ERROR](localState, payload);
      });

      it('updates subscriptionSyncStatus', () => {
        expect(localState.subscriptionSyncStatus).toBe(payload);
      });

      it('updates shouldShowNotifications', () => {
        expect(localState.breakdown.shouldShowNotifications).toBe(true);
      });

      it('updates hasAsyncActivity', () => {
        expect(localState.breakdown.hasAsyncActivity).toBe(false);
      });
    });

    describe('RECEIVE_SYNC_SUCCESS', () => {
      const payload = 'anything';

      beforeEach(() => {
        mutations[types.RECEIVE_SYNC_SUCCESS](localState, payload);
      });

      it('updates subscriptionSyncStatus', () => {
        expect(localState.subscriptionSyncStatus).toBe(payload);
      });

      it('updates shouldShowNotifications', () => {
        expect(localState.breakdown.shouldShowNotifications).toBe(true);
      });

      it('updates hasAsyncActivity', () => {
        expect(localState.breakdown.hasAsyncActivity).toBe(false);
      });
    });
  });

  describe('Remove license', () => {
    it('REQUEST_REMOVE_LICENSE updates hasAsyncActivity', () => {
      mutations[types.REQUEST_REMOVE_LICENSE](localState);

      expect(localState.breakdown.hasAsyncActivity).toBe(true);
    });

    describe('RECEIVE_REMOVE_LICENSE_ERROR', () => {
      const payload = 'an error message';

      beforeEach(() => {
        mutations[types.RECEIVE_REMOVE_LICENSE_ERROR](localState, payload);
      });

      it('updates hasAsyncActivity', () => {
        expect(localState.breakdown.hasAsyncActivity).toBe(false);
      });

      it('updates licenseError', () => {
        expect(localState.breakdown.licenseError).toBe(payload);
      });
    });

    it('RECEIVE_REMOVE_LICENSE_SUCCESS updates hasAsyncActivity', () => {
      mutations[types.RECEIVE_REMOVE_LICENSE_SUCCESS](localState);

      expect(localState.breakdown.hasAsyncActivity).toBe(false);
    });
  });

  describe('Dismiss alert', () => {
    describe('REQUEST_DISMISS_ALERT', () => {
      beforeEach(() => {
        mutations[types.REQUEST_DISMISS_ALERT](localState);
      });

      it('updates shouldShowNotifications', () => {
        expect(localState.breakdown.shouldShowNotifications).toBe(false);
      });

      it('updates alertableError', () => {
        expect(localState.breakdown.licenseError).toBe(null);
      });
    });
  });
});
