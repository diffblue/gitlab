import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/codequality_report/store/actions';
import initialState from 'ee/codequality_report/store/state';
import { VIEW_EVENT_NAME } from 'ee/codequality_report/store/constants';
import * as types from 'ee/codequality_report/store/mutation_types';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { unparsedIssues, parsedIssues } from '../mock_data';

jest.mock('~/api.js');
jest.mock('~/alert');

describe('Codequality report actions', () => {
  let mock;
  let state;

  const endpoint = `${TEST_HOST}/codequality_report.json`;
  const defaultState = {
    ...initialState(),
    endpoint,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = defaultState;
    window.gon = { features: {} };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setPage', () => {
    it('sets the page number', async () => {
      await testAction(actions.setPage, 12, state, [{ type: types.SET_PAGE, payload: 12 }], []);
    });
  });

  describe('requestReport', () => {
    it('sets the loading flag', async () => {
      await testAction(actions.requestReport, null, state, [{ type: types.REQUEST_REPORT }], []);
    });

    it('tracks a service ping event', () => {
      actions.requestReport({ commit: jest.fn() });

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(VIEW_EVENT_NAME);
    });
  });

  describe('receiveReportSuccess', () => {
    it('parses the list of issues from the report', async () => {
      await testAction(
        actions.receiveReportSuccess,
        unparsedIssues,
        { blobPath: '/root/test-codequality/blob/feature-branch', ...state },
        [{ type: types.RECEIVE_REPORT_SUCCESS, payload: parsedIssues }],
        [],
      );
    });
  });

  describe('receiveReportError', () => {
    it('accepts a report error', async () => {
      await testAction(
        actions.receiveReportError,
        'error',
        state,
        [{ type: types.RECEIVE_REPORT_ERROR, payload: 'error' }],
        [],
      );
    });
  });

  describe('fetchReport', () => {
    beforeEach(() => {
      mock.onGet(endpoint).replyOnce(HTTP_STATUS_OK, unparsedIssues);
    });

    it('fetches the report', async () => {
      await testAction(
        actions.fetchReport,
        null,
        { blobPath: 'blah', ...state },
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportSuccess', payload: unparsedIssues }],
      );
    });

    it('shows an alert message when there is an error', async () => {
      await testAction(
        actions.fetchReport,
        'error',
        state,
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportError', payload: expect.any(Error) }],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error fetching the codequality report.',
      });
    });

    it('shows an error when blob path is missing', async () => {
      await testAction(
        actions.fetchReport,
        null,
        state,
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportError', payload: expect.any(Error) }],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error fetching the codequality report.',
      });
    });
  });
});
