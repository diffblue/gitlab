import MockAdapter from 'axios-mock-adapter';

import * as actions from 'ee/billings/subscriptions/store/actions';
import * as types from 'ee/billings/subscriptions/store/mutation_types';
import state from 'ee/billings/subscriptions/store/state';
import { mockDataSubscription } from 'ee_jest/billings/mock_data';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('subscription actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setNamespaceId', () => {
    it('should commit the correct mutuation', () => {
      const namespaceId = 1;

      testAction(
        actions.setNamespaceId,
        namespaceId,
        mockedState,
        [
          {
            type: types.SET_NAMESPACE_ID,
            payload: namespaceId,
          },
        ],
        [],
      );
    });
  });

  describe('fetchSubscription', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
      mockedState.namespaceId = 1;
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(/\/api\/v4\/namespaces\/\d+\/gitlab_subscription(.*)$/)
          .replyOnce(HTTP_STATUS_OK, mockDataSubscription.gold);
      });

      it('should dispatch the request and success actions', () => {
        testAction(
          actions.fetchSubscription,
          {},
          mockedState,
          [],
          [
            { type: 'requestSubscription' },
            {
              type: 'receiveSubscriptionSuccess',
              payload: mockDataSubscription.gold,
            },
          ],
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock
          .onGet(/\/api\/v4\/namespaces\/\d+\/gitlab_subscription(.*)$/)
          .replyOnce(HTTP_STATUS_NOT_FOUND, {});
      });

      it('should dispatch the request and error actions', () => {
        testAction(
          actions.fetchSubscription,
          {},
          mockedState,
          [],
          [{ type: 'requestSubscription' }, { type: 'receiveSubscriptionError' }],
        );
      });
    });
  });

  describe('requestSubscription', () => {
    it('should commit the request mutation', () => {
      testAction(
        actions.requestSubscription,
        {},
        state,
        [{ type: types.REQUEST_SUBSCRIPTION }],
        [],
      );
    });
  });

  describe('receiveSubscriptionSuccess', () => {
    it('should commit the success mutation', () => {
      testAction(
        actions.receiveSubscriptionSuccess,
        mockDataSubscription.gold,
        mockedState,
        [
          {
            type: types.RECEIVE_SUBSCRIPTION_SUCCESS,
            payload: mockDataSubscription.gold,
          },
        ],
        [],
      );
    });
  });

  describe('receiveSubscriptionError', () => {
    it('should commit the error mutation', () => {
      testAction(
        actions.receiveSubscriptionError,
        {},
        mockedState,
        [{ type: types.RECEIVE_SUBSCRIPTION_ERROR }],
        [],
      );
    });
  });
});
