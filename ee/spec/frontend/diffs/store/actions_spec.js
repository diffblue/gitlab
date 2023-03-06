import MockAdapter from 'axios-mock-adapter';
import {
  setCodequalityEndpoint,
  clearCodequalityPoll,
  stopCodequalityPolling,
  fetchCodequality,
} from 'ee/diffs/store/actions';
import { RETRY_DELAY } from 'ee/diffs/store/constants';
import * as types from 'ee/diffs/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';

jest.mock('~/alert');

describe('EE DiffsStoreActions', () => {
  describe('setCodequalityEndpoint', () => {
    it('should set given endpoint', async () => {
      const endpoint = '/codequality_mr_diff.json';

      await testAction(
        setCodequalityEndpoint,
        { endpoint },
        {},
        [{ type: types.SET_CODEQUALITY_ENDPOINT, payload: { endpoint } }],
        [],
      );
    });
  });

  describe('fetchCodequality', () => {
    let mock;
    const endpointCodequality = '/codequality_mr_diff.json';

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      stopCodequalityPolling();
      clearCodequalityPoll();
    });

    it('should commit SET_CODEQUALITY_DATA with received response and stop polling', async () => {
      const data = {
        files: { 'app.js': [{ line: 1, description: 'Unexpected alert.', severity: 'minor' }] },
      };

      mock.onGet(endpointCodequality).reply(HTTP_STATUS_OK, { data });

      await testAction(
        fetchCodequality,
        {},
        { endpointCodequality },
        [{ type: types.SET_CODEQUALITY_DATA, payload: { data } }],
        [{ type: 'stopCodequalityPolling' }],
      );
    });

    describe('with 400 status response', () => {
      let pollDelayedRequest;
      let pollStop;

      beforeEach(() => {
        pollDelayedRequest = jest.spyOn(Poll.prototype, 'makeDelayedRequest');
        pollStop = jest.spyOn(Poll.prototype, 'stop');

        mock.onGet(endpointCodequality).reply(HTTP_STATUS_BAD_REQUEST);
      });

      it('should not show an alert message', async () => {
        await testAction(fetchCodequality, {}, { endpointCodequality }, [], []);

        expect(createAlert).not.toHaveBeenCalled();
      });

      it('should retry five times with a delay, then stop polling', async () => {
        await testAction(fetchCodequality, {}, { endpointCodequality }, [], []);

        expect(pollDelayedRequest).toHaveBeenCalledTimes(1);
        expect(pollStop).toHaveBeenCalledTimes(0);

        jest.advanceTimersByTime(RETRY_DELAY);

        return waitForPromises()
          .then(() => {
            expect(pollDelayedRequest).toHaveBeenCalledTimes(2);

            jest.advanceTimersByTime(RETRY_DELAY);
          })
          .then(() => waitForPromises())
          .then(() => jest.advanceTimersByTime(RETRY_DELAY))
          .then(() => waitForPromises())
          .then(() => jest.advanceTimersByTime(RETRY_DELAY))
          .then(() => waitForPromises())
          .then(() => {
            expect(pollDelayedRequest).toHaveBeenCalledTimes(5);

            jest.advanceTimersByTime(RETRY_DELAY);
          })
          .then(() => waitForPromises())
          .then(() => {
            expect(pollStop).toHaveBeenCalledTimes(1);
          });
      });
    });

    it('with unexpected error should stop polling and show an alert message', async () => {
      mock.onGet(endpointCodequality).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await testAction(
        fetchCodequality,
        {},
        { endpointCodequality },
        [],
        [{ type: 'stopCodequalityPolling' }],
      );
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An unexpected error occurred while loading the code quality diff.',
      });
    });
  });
});
