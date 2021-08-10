import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/codequality_report/store/actions';
import { VIEW_EVENT_NAME } from 'ee/codequality_report/store/constants';
import * as types from 'ee/codequality_report/store/mutation_types';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { unparsedIssues, parsedIssues } from '../mock_data';

jest.mock('~/api.js');
jest.mock('~/flash');

describe('Codequality report actions', () => {
  let mock;
  let state;

  const endpoint = `${TEST_HOST}/codequality_report.json`;
  const defaultState = {
    endpoint,
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = defaultState;
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setPage', () => {
    it('sets the page number', (done) => {
      testAction(actions.setPage, 12, state, [{ type: types.SET_PAGE, payload: 12 }], [], done);
    });
  });

  describe('requestReport', () => {
    it('sets the loading flag', (done) => {
      testAction(actions.requestReport, null, state, [{ type: types.REQUEST_REPORT }], [], done);
    });

    it('tracks a service ping event', () => {
      actions.requestReport({ commit: jest.fn() });

      expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(VIEW_EVENT_NAME);
    });
  });

  describe('receiveReportSuccess', () => {
    it('parses the list of issues from the report', (done) => {
      testAction(
        actions.receiveReportSuccess,
        unparsedIssues,
        { blobPath: '/root/test-codequality/blob/feature-branch', ...state },
        [{ type: types.RECEIVE_REPORT_SUCCESS, payload: parsedIssues }],
        [],
        done,
      );
    });
  });

  describe('receiveReportError', () => {
    it('accepts a report error', (done) => {
      testAction(
        actions.receiveReportError,
        'error',
        state,
        [{ type: types.RECEIVE_REPORT_ERROR, payload: 'error' }],
        [],
        done,
      );
    });
  });

  describe('fetchReport', () => {
    beforeEach(() => {
      mock.onGet(endpoint).replyOnce(200, unparsedIssues);
    });

    it('fetches the report', (done) => {
      testAction(
        actions.fetchReport,
        null,
        { blobPath: 'blah', ...state },
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportSuccess', payload: unparsedIssues }],
        done,
      );
    });

    it('shows a flash message when there is an error', (done) => {
      testAction(
        actions.fetchReport,
        'error',
        state,
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportError', payload: new Error() }],
        () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was an error fetching the codequality report.',
          });
          done();
        },
      );
    });

    it('shows an error when blob path is missing', (done) => {
      testAction(
        actions.fetchReport,
        null,
        state,
        [],
        [{ type: 'requestReport' }, { type: 'receiveReportError', payload: new Error() }],
        () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was an error fetching the codequality report.',
          });
          done();
        },
      );
    });
  });
});
