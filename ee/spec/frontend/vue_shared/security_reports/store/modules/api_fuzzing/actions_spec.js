import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/actions';
import * as types from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/mutation_types';
import createState from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';

const diffEndpoint = 'diff-endpoint.json';
const blobPath = 'blob-path.json';
const reports = {
  base: 'base',
  head: 'head',
  enrichData: 'enrichData',
  diff: 'diff',
};
const error = 'Something went wrong';
const vulnerabilityFeedbackPath = 'vulnerability-feedback-path';
const rootState = { vulnerabilityFeedbackPath, blobPath };
const issue = {};
let state;

describe('EE api fuzzing report actions', () => {
  beforeEach(() => {
    state = createState();
  });

  describe('updateVulnerability', () => {
    it(`should commit ${types.UPDATE_VULNERABILITY} with the correct response`, async () => {
      await testAction(
        actions.updateVulnerability,
        issue,
        state,
        [
          {
            type: types.UPDATE_VULNERABILITY,
            payload: issue,
          },
        ],
        [],
      );
    });
  });

  describe('setDiffEndpoint', () => {
    it(`should commit ${types.SET_DIFF_ENDPOINT} with the correct path`, async () => {
      await testAction(
        actions.setDiffEndpoint,
        diffEndpoint,
        state,
        [
          {
            type: types.SET_DIFF_ENDPOINT,
            payload: diffEndpoint,
          },
        ],
        [],
      );
    });
  });

  describe('requestDiff', () => {
    it(`should commit ${types.REQUEST_DIFF}`, async () => {
      await testAction(actions.requestDiff, {}, state, [{ type: types.REQUEST_DIFF }], []);
    });
  });

  describe('receiveDiffSuccess', () => {
    it(`should commit ${types.RECEIVE_DIFF_SUCCESS} with the correct response`, async () => {
      await testAction(
        actions.receiveDiffSuccess,
        reports,
        state,
        [
          {
            type: types.RECEIVE_DIFF_SUCCESS,
            payload: reports,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDiffError', () => {
    it(`should commit ${types.RECEIVE_DIFF_ERROR} with the correct response`, async () => {
      await testAction(
        actions.receiveDiffError,
        error,
        state,
        [
          {
            type: types.RECEIVE_DIFF_ERROR,
            payload: error,
          },
        ],
        [],
      );
    });
  });

  describe('fetchDiff', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state.paths.diffEndpoint = diffEndpoint;
      rootState.canReadVulnerabilityFeedback = true;
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when diff and vulnerability feedback endpoints respond successfully', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(HTTP_STATUS_OK, reports.diff)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(HTTP_STATUS_OK, reports.enrichData);
      });

      it('should dispatch the `receiveDiffSuccess` action', async () => {
        const { diff, enrichData } = reports;
        await testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [
            { type: 'requestDiff' },
            {
              type: 'receiveDiffSuccess',
              payload: {
                diff,
                enrichData,
              },
            },
          ],
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        rootState.canReadVulnerabilityFeedback = false;
        mock.onGet(diffEndpoint).replyOnce(HTTP_STATUS_OK, reports.diff);
      });

      it('should dispatch the `receiveDiffSuccess` action with empty enrich data', async () => {
        const { diff } = reports;
        const enrichData = [];
        await testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [
            { type: 'requestDiff' },
            {
              type: 'receiveDiffSuccess',
              payload: {
                diff,
                enrichData,
              },
            },
          ],
        );
      });
    });

    describe('when the vulnerability feedback endpoint fails', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(HTTP_STATUS_OK, reports.diff)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(HTTP_STATUS_NOT_FOUND);
      });

      it('should dispatch the `receiveError` action', async () => {
        await testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [{ type: 'requestDiff' }, { type: 'receiveDiffError' }],
        );
      });
    });

    describe('when the diff endpoint fails', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(HTTP_STATUS_NOT_FOUND)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(HTTP_STATUS_OK, reports.enrichData);
      });

      it('should dispatch the `receiveDiffError` action', async () => {
        await testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [{ type: 'requestDiff' }, { type: 'receiveDiffError' }],
        );
      });
    });
  });
});
