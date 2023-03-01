import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { HTTP_STATUS_OK, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import {
  syncSubscription,
  removeLicense,
  removeLicenseSuccess,
  dismissAlert,
} from 'ee/admin/subscriptions/show/store/actions';
import { subscriptionSyncStatus } from 'ee/admin/subscriptions/show/constants';
import createState from 'ee/admin/subscriptions/show/store/state';
import * as types from 'ee/admin/subscriptions/show/store/mutation_types';

describe('Admin Subscriptions Show Actions', () => {
  let state;
  let axiosMock;

  beforeEach(() => {
    state = createState({ licenseRemovePath: '', subscriptionSyncPath: '' });
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('syncSubscription', () => {
    const requestMutation = {
      type: types.REQUEST_SYNC,
      payload: subscriptionSyncStatus.SYNC_PENDING,
    };

    beforeEach(() => {
      jest.spyOn(axios, 'post');
    });

    afterEach(() => {
      jest.resetAllMocks();
    });

    describe('when axios response is successful', () => {
      const successMutation = {
        type: types.RECEIVE_SYNC_SUCCESS,
        payload: subscriptionSyncStatus.SYNC_SUCCESS,
      };

      beforeEach(() => {
        axiosMock.onPost().replyOnce(HTTP_STATUS_OK);
      });

      it('triggers REQUEST_SYNC and RECEIVE_SYNC_SUCCESS', async () => {
        await testAction({
          action: syncSubscription,
          payload: [],
          state,
          expectedMutations: [requestMutation, successMutation],
          expectedActions: [],
        });
      });

      it('triggers axios post call', async () => {
        await syncSubscription({
          commit: () => {},
          state,
        });

        expect(axios.post).toHaveBeenCalled();
      });
    });

    describe('when axios response errors', () => {
      const errorMutation = {
        type: types.RECEIVE_SYNC_ERROR,
        payload: subscriptionSyncStatus.SYNC_FAILURE,
      };

      beforeEach(() => {
        axiosMock.onPost().replyOnce(HTTP_STATUS_UNAUTHORIZED);
      });

      it('triggers REQUEST_SYNC and RECEIVE_SYNC_ERROR', async () => {
        await testAction({
          action: syncSubscription,
          payload: [],
          state,
          expectedMutations: [requestMutation, errorMutation],
          expectedActions: [],
        });
      });

      it('triggers axios post call', async () => {
        await syncSubscription({
          commit: () => {},
          state,
        });

        expect(axios.post).toHaveBeenCalled();
      });
    });
  });

  describe('removeLicense', () => {
    const requestMutation = {
      type: types.REQUEST_REMOVE_LICENSE,
    };

    beforeEach(() => {
      jest.spyOn(axios, 'delete');
    });

    afterEach(() => {
      jest.resetAllMocks();
    });

    describe('when axios response is successful', () => {
      beforeEach(() => {
        axiosMock.onDelete().replyOnce(HTTP_STATUS_OK);
      });

      it('triggers REQUEST_REMOVE_LICENSE and removeLicenseSuccess action', async () => {
        await testAction({
          action: removeLicense,
          payload: [],
          state,
          expectedMutations: [requestMutation],
          expectedActions: [{ type: 'removeLicenseSuccess' }],
        });
      });

      it('triggers axios delete call', async () => {
        await removeLicense({
          commit: () => {},
          dispatch: () => {},
          state,
        });

        expect(axios.delete).toHaveBeenCalled();
      });
    });

    describe('when axios response errors', () => {
      const err = new Error(`Request failed with status code ${HTTP_STATUS_UNAUTHORIZED}`);
      const errorMutation = {
        type: types.RECEIVE_REMOVE_LICENSE_ERROR,
        payload: err,
      };

      beforeEach(() => {
        axiosMock.onDelete().replyOnce(HTTP_STATUS_UNAUTHORIZED);
      });

      it('triggers REQUEST_REMOVE_LICENSE and RECEIVE_REMOVE_LICENSE_ERROR', async () => {
        await testAction({
          action: removeLicense,
          payload: [],
          state,
          expectedMutations: [requestMutation, errorMutation],
          expectedActions: [],
        });
      });

      it('triggers axios delete call', async () => {
        await removeLicense({
          commit: () => {},
          dispatch: () => {},
          state,
        });

        expect(axios.delete).toHaveBeenCalled();
      });
    });
  });

  describe('removeLicenseSuccess', () => {
    const successMutation = { type: types.RECEIVE_REMOVE_LICENSE_SUCCESS };

    it('triggers RECEIVE_REMOVE_LICENSE_SUCCESS', async () => {
      await testAction({
        action: removeLicenseSuccess,
        payload: [],
        state,
        expectedMutations: [successMutation],
        expectedActions: [],
      });
    });
  });

  describe('dismissAlert', () => {
    it('triggers REQUEST_DISMISS_ALERT mutation', async () => {
      await testAction({
        action: dismissAlert,
        payload: [],
        state,
        expectedMutations: [{ type: types.REQUEST_DISMISS_ALERT }],
        expectedActions: [],
      });
    });
  });
});
