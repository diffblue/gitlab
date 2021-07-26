import MockAdapter from 'axios-mock-adapter';
import {
  setHeadBlobPath,
  setBaseBlobPath,
  setCanReadVulnerabilityFeedback,
  setVulnerabilityFeedbackPath,
  setPipelineId,
  requestContainerScanningDiff,
  requestDastDiff,
  requestDependencyScanningDiff,
  requestCoverageFuzzingDiff,
  setModalData,
  requestDismissVulnerability,
  receiveDismissVulnerability,
  receiveDismissVulnerabilityError,
  dismissVulnerability,
  revertDismissVulnerability,
  requestCreateIssue,
  receiveCreateIssue,
  receiveCreateIssueError,
  createNewIssue,
  downloadPatch,
  requestCreateMergeRequest,
  receiveCreateMergeRequestSuccess,
  receiveCreateMergeRequestError,
  createMergeRequest,
  updateDependencyScanningIssue,
  updateContainerScanningIssue,
  updateDastIssue,
  updateCoverageFuzzingIssue,
  addDismissalComment,
  receiveAddDismissalCommentError,
  receiveAddDismissalCommentSuccess,
  requestAddDismissalComment,
  deleteDismissalComment,
  receiveDeleteDismissalCommentError,
  receiveDeleteDismissalCommentSuccess,
  requestDeleteDismissalComment,
  showDismissalDeleteButtons,
  hideDismissalDeleteButtons,
  setContainerScanningDiffEndpoint,
  receiveContainerScanningDiffSuccess,
  receiveContainerScanningDiffError,
  fetchContainerScanningDiff,
  setDependencyScanningDiffEndpoint,
  receiveDependencyScanningDiffSuccess,
  receiveDependencyScanningDiffError,
  fetchDependencyScanningDiff,
  setDastDiffEndpoint,
  receiveDastDiffSuccess,
  receiveDastDiffError,
  fetchDastDiff,
  setCoverageFuzzingDiffEndpoint,
  receiveCoverageFuzzingDiffSuccess,
  receiveCoverageFuzzingDiffError,
  fetchCoverageFuzzingDiff,
} from 'ee/vue_shared/security_reports/store/actions';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import state from 'ee/vue_shared/security_reports/store/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import toasted from '~/vue_shared/plugins/global_toast';
import {
  dastFeedbacks,
  containerScanningFeedbacks,
  dependencyScanningFeedbacks,
  coverageFuzzingFeedbacks,
} from '../mock_data';

// Mock bootstrap modal implementation
jest.mock('jquery', () => () => ({
  modal: jest.fn(),
}));
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
}));

jest.mock('~/vue_shared/plugins/global_toast', () => jest.fn());

const createVulnerability = (options) => ({
  ...options,
});

const createNonDismissedVulnerability = (options) =>
  createVulnerability({
    ...options,
    isDismissed: false,
    dismissalFeedback: null,
    dismissal_feedback: null,
  });

const createDismissedVulnerability = (options) =>
  createVulnerability({
    ...options,
    isDismissed: true,
  });

afterEach(() => {
  jest.clearAllMocks();
});

describe('security reports actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    toasted.mockClear();
  });

  describe('setHeadBlobPath', () => {
    it('should commit set head blob path', (done) => {
      testAction(
        setHeadBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_HEAD_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setBaseBlobPath', () => {
    it('should commit set head blob path', (done) => {
      testAction(
        setBaseBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_BASE_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setCanReadVulnerabilityFeedback', () => {
    it('should commit set vulnerabulity feedback path', (done) => {
      testAction(
        setCanReadVulnerabilityFeedback,
        true,
        mockedState,
        [
          {
            type: types.SET_CAN_READ_VULNERABILITY_FEEDBACK,
            payload: true,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setVulnerabilityFeedbackPath', () => {
    it('should commit set vulnerabulity feedback path', (done) => {
      testAction(
        setVulnerabilityFeedbackPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_VULNERABILITY_FEEDBACK_PATH,
            payload: 'path',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setPipelineId', () => {
    it('should commit set vulnerability feedback path', (done) => {
      testAction(
        setPipelineId,
        123,
        mockedState,
        [
          {
            type: types.SET_PIPELINE_ID,
            payload: 123,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestContainerScanningDiff', () => {
    it('should commit request mutation', (done) => {
      testAction(
        requestContainerScanningDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CONTAINER_SCANNING_DIFF,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDastDiff', () => {
    it('should commit request mutation', (done) => {
      testAction(
        requestDastDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DAST_DIFF,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDependencyScanningDiff', () => {
    it('should commit request mutation', (done) => {
      testAction(
        requestDependencyScanningDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DEPENDENCY_SCANNING_DIFF,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestCoverageFuzzingDiff', () => {
    it('should commit request mutation', (done) => {
      testAction(
        requestCoverageFuzzingDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_COVERAGE_FUZZING_DIFF,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setModalData', () => {
    it('commits set issue modal data', (done) => {
      testAction(
        setModalData,
        { issue: { id: 1 }, status: 'success' },
        mockedState,
        [
          {
            type: types.SET_ISSUE_MODAL_DATA,
            payload: { issue: { id: 1 }, status: 'success' },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDismissVulnerability', () => {
    it('commits request dismiss issue', (done) => {
      testAction(
        requestDismissVulnerability,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DISMISS_VULNERABILITY,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissVulnerability', () => {
    it(`should pass the payload to the ${types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS} mutation`, (done) => {
      const payload = createDismissedVulnerability();

      testAction(
        receiveDismissVulnerability,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDismissVulnerabilityError', () => {
    it('commits receive dismiss issue error with payload', (done) => {
      testAction(
        receiveDismissVulnerabilityError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_ERROR,
            payload: 'error',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('dismissVulnerability', () => {
    describe('with success', () => {
      let payload;
      let dismissalFeedback;

      beforeEach(() => {
        dismissalFeedback = {
          foo: 'bar',
        };
        payload = createDismissedVulnerability({
          ...mockedState.modal.vulnerability,
          dismissalFeedback,
        });
        mock.onPost('dismiss_vulnerability_path').reply(200, dismissalFeedback);
        mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';
      });

      it(`should dispatch receiveDismissVulnerability`, (done) => {
        testAction(
          dismissVulnerability,
          payload,
          mockedState,
          [],
          [
            {
              type: 'requestDismissVulnerability',
            },
            {
              type: 'closeDismissalCommentBox',
            },
            {
              type: 'receiveDismissVulnerability',
              payload,
            },
          ],
          done,
        );
      });

      it('show dismiss vulnerability toast message', (done) => {
        const checkToastMessage = () => {
          expect(toasted).toHaveBeenCalledTimes(1);
          done();
        };

        testAction(
          dismissVulnerability,
          payload,
          mockedState,
          [],
          [
            {
              type: 'requestDismissVulnerability',
            },
            {
              type: 'closeDismissalCommentBox',
            },
            {
              type: 'receiveDismissVulnerability',
              payload,
            },
          ],
          checkToastMessage,
        );
      });
    });

    describe.each`
      httpStatusErrorCode                      | expectedErrorMessage
      ${httpStatusCodes.INTERNAL_SERVER_ERROR} | ${'There was an error dismissing the vulnerability. Please try again.'}
      ${httpStatusCodes.UNPROCESSABLE_ENTITY}  | ${'Could not dismiss vulnerability because the associated pipeline no longer exists. Refresh the page and try again.'}
    `('with error "$httpStatusErrorCode"', ({ httpStatusErrorCode, expectedErrorMessage }) => {
      beforeEach(() => {
        mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';
        mockedState.canReadVulnerabilityFeedback = true;
      });

      it('should dispatch `receiveDismissVulnerabilityError` with the correct payload', (done) => {
        mock
          .onPost(mockedState.createVulnerabilityFeedbackDismissalPath)
          .replyOnce(httpStatusErrorCode);

        testAction(
          dismissVulnerability,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDismissVulnerability',
            },
            {
              type: 'receiveDismissVulnerabilityError',
              payload: expectedErrorMessage,
            },
          ],
          done,
        );
      });
    });
  });

  describe('addDismissalComment', () => {
    const vulnerability = {
      id: 0,
      vulnerability_feedback_dismissal_path: 'foo',
      dismissalFeedback: { id: 1 },
    };
    const data = { vulnerability };
    const url = `${state.createVulnerabilityFeedbackDismissalPath}/${vulnerability.dismissalFeedback.id}`;
    const comment = 'Well, we’re back in the car again.';

    describe('on success', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(200, data);
      });

      it('should dispatch the request and success actions', (done) => {
        testAction(
          addDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestAddDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveAddDismissalCommentSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });

      it('should show added dismissal comment toast message', (done) => {
        const checkToastMessage = () => {
          expect(toasted).toHaveBeenCalledTimes(1);
          done();
        };

        testAction(
          addDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestAddDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveAddDismissalCommentSuccess',
              payload: { data },
            },
          ],
          checkToastMessage,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(404);
      });

      it('should dispatch the request and error actions', (done) => {
        testAction(
          addDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestAddDismissalComment' },
            {
              type: 'receiveAddDismissalCommentError',
              payload: 'There was an error adding the comment.',
            },
          ],
          done,
        );
      });
    });

    describe('receiveAddDismissalCommentSuccess', () => {
      it('should commit the success mutation', (done) => {
        testAction(
          receiveAddDismissalCommentSuccess,
          { data },
          state,
          [{ type: types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload: { data } }],
          [],
          done,
        );
      });
    });

    describe('receiveAddDismissalCommentError', () => {
      it('should commit the error mutation', (done) => {
        testAction(
          receiveAddDismissalCommentError,
          {},
          state,
          [
            {
              type: types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR,
              payload: {},
            },
          ],
          [],
          done,
        );
      });
    });

    describe('requestAddDismissalComment', () => {
      it('should commit the request mutation', (done) => {
        testAction(
          requestAddDismissalComment,
          {},
          state,
          [{ type: types.REQUEST_ADD_DISMISSAL_COMMENT }],
          [],
          done,
        );
      });
    });
  });

  describe('deleteDismissalComment', () => {
    const vulnerability = {
      id: 0,
      vulnerability_feedback_dismissal_path: 'foo',
      dismissalFeedback: { id: 1 },
    };
    const data = { vulnerability };
    const url = `${state.createVulnerabilityFeedbackDismissalPath}/${vulnerability.dismissalFeedback.id}`;
    const comment = '';

    describe('on success', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(200, data);
      });

      it('should dispatch the request and success actions', (done) => {
        testAction(
          deleteDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDeleteDismissalCommentSuccess',
              payload: { data },
            },
          ],
          done,
        );
      });

      it('should show deleted dismissal comment toast message', (done) => {
        const checkToastMessage = () => {
          expect(toasted).toHaveBeenCalledTimes(1);
          done();
        };

        testAction(
          deleteDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            { type: 'closeDismissalCommentBox' },
            {
              type: 'receiveDeleteDismissalCommentSuccess',
              payload: { data },
            },
          ],
          checkToastMessage,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(404);
      });

      it('should dispatch the request and error actions', (done) => {
        testAction(
          deleteDismissalComment,
          { comment },
          { modal: { vulnerability } },
          [],
          [
            { type: 'requestDeleteDismissalComment' },
            {
              type: 'receiveDeleteDismissalCommentError',
              payload: 'There was an error deleting the comment.',
            },
          ],
          done,
        );
      });
    });

    describe('receiveDeleteDismissalCommentSuccess', () => {
      it('should commit the success mutation', (done) => {
        testAction(
          receiveDeleteDismissalCommentSuccess,
          { data },
          state,
          [{ type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload: { data } }],
          [],
          done,
        );
      });
    });

    describe('receiveDeleteDismissalCommentError', () => {
      it('should commit the error mutation', (done) => {
        testAction(
          receiveDeleteDismissalCommentError,
          {},
          state,
          [
            {
              type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR,
              payload: {},
            },
          ],
          [],
          done,
        );
      });
    });

    describe('requestDeleteDismissalComment', () => {
      it('should commit the request mutation', (done) => {
        testAction(
          requestDeleteDismissalComment,
          {},
          state,
          [{ type: types.REQUEST_DELETE_DISMISSAL_COMMENT }],
          [],
          done,
        );
      });
    });
  });

  describe('showDismissalDeleteButtons', () => {
    it('commits show dismissal delete buttons', (done) => {
      testAction(
        showDismissalDeleteButtons,
        null,
        mockedState,
        [
          {
            type: types.SHOW_DISMISSAL_DELETE_BUTTONS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('hideDismissalDeleteButtons', () => {
    it('commits hide dismissal delete buttons', (done) => {
      testAction(
        hideDismissalDeleteButtons,
        null,
        mockedState,
        [
          {
            type: types.HIDE_DISMISSAL_DELETE_BUTTONS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('revertDismissVulnerability', () => {
    describe('with success', () => {
      let payload;

      beforeEach(() => {
        mock.onDelete('dismiss_vulnerability_path/123').reply(200, {});
        mockedState.modal.vulnerability.dismissalFeedback = {
          id: 123,
          destroy_vulnerability_feedback_dismissal_path: 'dismiss_vulnerability_path/123',
        };
        payload = createNonDismissedVulnerability({ ...mockedState.modal.vulnerability });
      });

      it('should dispatch `receiveDismissVulnerability`', (done) => {
        testAction(
          revertDismissVulnerability,
          payload,
          mockedState,
          [],
          [
            {
              type: 'requestDismissVulnerability',
            },
            {
              type: 'receiveDismissVulnerability',
              payload,
            },
          ],
          done,
        );
      });
    });

    it('with error should dispatch `receiveDismissVulnerabilityError`', (done) => {
      mock.onDelete('dismiss_vulnerability_path/123').reply(500, {});
      mockedState.modal.vulnerability.dismissalFeedback = { id: 123 };
      mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';

      testAction(
        revertDismissVulnerability,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestDismissVulnerability',
          },
          {
            type: 'receiveDismissVulnerabilityError',
            payload: 'There was an error reverting the dismissal. Please try again.',
          },
        ],
        done,
      );
    });
  });

  describe('requestCreateIssue', () => {
    it('commits request create issue', (done) => {
      testAction(
        requestCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CREATE_ISSUE,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssue', () => {
    it('commits receive create issue', (done) => {
      testAction(
        receiveCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_SUCCESS,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateIssueError', () => {
    it('commits receive create issue error with payload', (done) => {
      testAction(
        receiveCreateIssueError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_ERROR,
            payload: 'error',
          },
        ],
        [],
        done,
      );
    });
  });

  describe('createNewIssue', () => {
    it('with success should dispatch `requestCreateIssue` and `receiveCreateIssue`', (done) => {
      mock.onPost('create_issue_path').reply(200, { issue_path: 'new_issue' });
      mockedState.createVulnerabilityFeedbackIssuePath = 'create_issue_path';

      testAction(
        createNewIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateIssue',
          },
          {
            type: 'receiveCreateIssue',
          },
        ],
        done,
      );
    });

    it('with error should dispatch `receiveCreateIssueError`', (done) => {
      mock.onPost('create_issue_path').reply(500, {});
      mockedState.vulnerabilityFeedbackPath = 'create_issue_path';
      mockedState.canReadVulnerabilityFeedback = true;

      testAction(
        createNewIssue,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateIssue',
          },
          {
            type: 'receiveCreateIssueError',
            payload: 'There was an error creating the issue. Please try again.',
          },
        ],
        done,
      );
    });
  });

  describe('downloadPatch', () => {
    it('creates a download link and clicks on it to download the file', () => {
      const a = { click: jest.fn() };
      jest.spyOn(document, 'createElement').mockImplementation(() => a);

      downloadPatch({
        state: {
          modal: {
            vulnerability: {
              remediations: [
                {
                  diff: 'abcdef',
                },
              ],
            },
          },
        },
      });

      expect(document.createElement).toHaveBeenCalledTimes(1);
      expect(document.createElement).toHaveBeenCalledWith('a');
      expect(a.click).toHaveBeenCalledTimes(1);
      expect(a.download).toBe('remediation.patch');
      expect(a.href).toContain('data:text/plain;base64');
    });
  });

  describe('requestCreateMergeRequest', () => {
    it('commits request create merge request', (done) => {
      testAction(
        requestCreateMergeRequest,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CREATE_MERGE_REQUEST,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateMergeRequestSuccess', () => {
    it('commits receive create merge request', (done) => {
      const data = { foo: 'bar' };

      testAction(
        receiveCreateMergeRequestSuccess,
        data,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS,
            payload: data,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCreateMergeRequestError', () => {
    it('commits receive create merge request error', (done) => {
      testAction(
        receiveCreateMergeRequestError,
        '',
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_MERGE_REQUEST_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('createMergeRequest', () => {
    it('with success should dispatch `receiveCreateMergeRequestSuccess`', (done) => {
      const data = { merge_request_path: 'fakepath.html' };
      mockedState.createVulnerabilityFeedbackMergeRequestPath = 'create_merge_request_path';
      mock.onPost('create_merge_request_path').reply(200, data);

      testAction(
        createMergeRequest,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateMergeRequest',
          },
          {
            type: 'receiveCreateMergeRequestSuccess',
            payload: data,
          },
        ],
        done,
      );
    });

    it('with error should dispatch `receiveCreateMergeRequestError`', (done) => {
      mock.onPost('create_merge_request_path').reply(500, {});
      mockedState.vulnerabilityFeedbackPath = 'create_merge_request_path';
      mockedState.canReadVulnerabilityFeedback = true;

      testAction(
        createMergeRequest,
        null,
        mockedState,
        [],
        [
          {
            type: 'requestCreateMergeRequest',
          },
          {
            type: 'receiveCreateMergeRequestError',
            payload: 'There was an error creating the merge request. Please try again.',
          },
        ],
        done,
      );
    });
  });

  describe('updateDependencyScanningIssue', () => {
    it('commits update dependency scanning issue', (done) => {
      const payload = { foo: 'bar' };

      testAction(
        updateDependencyScanningIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_DEPENDENCY_SCANNING_ISSUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateContainerScanningIssue', () => {
    it('commits update container scanning issue', (done) => {
      const payload = { foo: 'bar' };

      testAction(
        updateContainerScanningIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_CONTAINER_SCANNING_ISSUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateDastIssue', () => {
    it('commits update dast issue', (done) => {
      const payload = { foo: 'bar' };

      testAction(
        updateDastIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_DAST_ISSUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('updateCoverageFuzzingIssue', () => {
    it('commits update coverageFuzzing issue', (done) => {
      const payload = { foo: 'bar' };

      testAction(
        updateCoverageFuzzingIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_COVERAGE_FUZZING_ISSUE,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setContainerScanningDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', (done) => {
      const payload = '/container_scanning_endpoint.json';

      testAction(
        setContainerScanningDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_CONTAINER_SCANNING_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveContainerScanningDiffSuccess', () => {
    it('should pass down the response to the mutation', (done) => {
      const payload = { data: 'Effort yields its own rewards.' };

      testAction(
        receiveContainerScanningDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveContainerScanningDiffError', () => {
    it('should commit container diff error mutation', (done) => {
      testAction(
        receiveContainerScanningDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_CONTAINER_SCANNING_DIFF_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchContainerScanningDiff', () => {
    const diff = { vulnerabilities: [] };
    const endpoint = 'container_scanning_diff.json';

    beforeEach(() => {
      mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_feedback';
      mockedState.canReadVulnerabilityFeedback = true;
      mockedState.containerScanning.paths.diffEndpoint = endpoint;
    });

    describe('on success', () => {
      it('should dispatch `receiveContainerScanningDiffSuccess`', (done) => {
        mock.onGet(endpoint).reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        testAction(
          fetchContainerScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestContainerScanningDiff',
            },
            {
              type: 'receiveContainerScanningDiffSuccess',
              payload: {
                diff,
                enrichData: containerScanningFeedbacks,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        mockedState.canReadVulnerabilityFeedback = false;
        mock.onGet(endpoint).reply(200, diff);
      });

      it('should dispatch `receiveContainerScanningDiffSuccess`', (done) => {
        testAction(
          fetchContainerScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestContainerScanningDiff',
            },
            {
              type: 'receiveContainerScanningDiffSuccess',
              payload: {
                diff,
                enrichData: [],
              },
            },
          ],
          done,
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveContainerScanningError`', (done) => {
        mock.onGet(endpoint).reply(500);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(200, containerScanningFeedbacks);

        testAction(
          fetchContainerScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestContainerScanningDiff',
            },
            {
              type: 'receiveContainerScanningDiffError',
            },
          ],
          done,
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveContainerScanningError`', (done) => {
        mock.onGet(endpoint).reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(500);

        testAction(
          fetchContainerScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestContainerScanningDiff',
            },
            {
              type: 'receiveContainerScanningDiffError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDependencyScanningDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', (done) => {
      const payload = '/dependency_scanning_endpoint.json';

      testAction(
        setDependencyScanningDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningDiffSuccess', () => {
    it('should pass down the response to the mutation', (done) => {
      const payload = { data: 'Effort yields its own rewards.' };

      testAction(
        receiveDependencyScanningDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDependencyScanningDiffError', () => {
    it('should commit dependency scanning diff error mutation', (done) => {
      testAction(
        receiveDependencyScanningDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDependencyScanningDiff', () => {
    const diff = { foo: {} };

    beforeEach(() => {
      mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_feedback';
      mockedState.canReadVulnerabilityFeedback = true;
      mockedState.dependencyScanning.paths.diffEndpoint = 'dependency_scanning_diff.json';
    });

    describe('on success', () => {
      it('should dispatch `receiveDependencyScanningDiffSuccess`', (done) => {
        mock.onGet('dependency_scanning_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, dependencyScanningFeedbacks);

        testAction(
          fetchDependencyScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningDiff',
            },
            {
              type: 'receiveDependencyScanningDiffSuccess',
              payload: {
                diff,
                enrichData: dependencyScanningFeedbacks,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        mockedState.canReadVulnerabilityFeedback = false;
        mock.onGet('dependency_scanning_diff.json').reply(200, diff);
      });

      it('should dispatch `receiveDependencyScanningDiffSuccess`', (done) => {
        testAction(
          fetchDependencyScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningDiff',
            },
            {
              type: 'receiveDependencyScanningDiffSuccess',
              payload: {
                diff,
                enrichData: [],
              },
            },
          ],
          done,
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveDependencyScanningError`', (done) => {
        mock.onGet('dependency_scanning_diff.json').reply(500);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(200, dependencyScanningFeedbacks);

        testAction(
          fetchDependencyScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningDiff',
            },
            {
              type: 'receiveDependencyScanningDiffError',
            },
          ],
          done,
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveDependencyScanningError`', (done) => {
        mock.onGet('dependency_scanning_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(500);

        testAction(
          fetchDependencyScanningDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDependencyScanningDiff',
            },
            {
              type: 'receiveDependencyScanningDiffError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setDastDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', (done) => {
      const payload = '/dast_endpoint.json';

      testAction(
        setDastDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_DAST_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastDiffSuccess', () => {
    it('should pass down the response to the mutation', (done) => {
      const payload = { data: 'Effort yields its own rewards.' };

      testAction(
        receiveDastDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDastDiffError', () => {
    it('should commit dast diff error mutation', (done) => {
      testAction(
        receiveDastDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_DIFF_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDastDiff', () => {
    const diff = { foo: {} };

    beforeEach(() => {
      mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_feedback';
      mockedState.canReadVulnerabilityFeedback = true;
      mockedState.dast.paths.diffEndpoint = 'dast_diff.json';
    });

    describe('on success', () => {
      it('should dispatch `receiveDastDiffSuccess`', (done) => {
        mock.onGet('dast_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        testAction(
          fetchDastDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastDiff',
            },
            {
              type: 'receiveDastDiffSuccess',
              payload: {
                diff,
                enrichData: dastFeedbacks,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        mockedState.canReadVulnerabilityFeedback = false;
        mock.onGet('dast_diff.json').reply(200, diff);
      });

      it('should dispatch `receiveDastDiffSuccess`', (done) => {
        testAction(
          fetchDastDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastDiff',
            },
            {
              type: 'receiveDastDiffSuccess',
              payload: {
                diff,
                enrichData: [],
              },
            },
          ],
          done,
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveDastError`', (done) => {
        mock.onGet('dast_diff.json').reply(500);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(200, dastFeedbacks);

        testAction(
          fetchDastDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastDiff',
            },
            {
              type: 'receiveDastDiffError',
            },
          ],
          done,
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveDastError`', (done) => {
        mock.onGet('dast_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(500);

        testAction(
          fetchDastDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestDastDiff',
            },
            {
              type: 'receiveDastDiffError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('setCoverageFuzzingDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', (done) => {
      const payload = '/coverage_fuzzing_endpoint.json';

      testAction(
        setCoverageFuzzingDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_COVERAGE_FUZZING_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCoverageFuzzingDiffSuccess', () => {
    it('should pass down the response to the mutation', (done) => {
      const payload = { data: 'Effort yields its own rewards.' };

      testAction(
        receiveCoverageFuzzingDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_COVERAGE_FUZZING_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveCoverageFuzzingDiffError', () => {
    it('should commit coverage fuzzing diff error mutation', (done) => {
      testAction(
        receiveCoverageFuzzingDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_COVERAGE_FUZZING_DIFF_ERROR,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetcCoverageFuzzingDiff', () => {
    const diff = { foo: {} };

    beforeEach(() => {
      mockedState.vulnerabilityFeedbackPath = 'vulnerabilities_feedback';
      mockedState.coverageFuzzing.paths.diffEndpoint = 'coverage_fuzzing_diff.json';
    });

    describe('on success', () => {
      it('should dispatch `receiveCoverageFuzzingDiffSuccess`', (done) => {
        mock.onGet('coverage_fuzzing_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'coverage_fuzzing',
            },
          })
          .reply(200, coverageFuzzingFeedbacks);

        testAction(
          fetchCoverageFuzzingDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestCoverageFuzzingDiff',
            },
            {
              type: 'receiveCoverageFuzzingDiffSuccess',
              payload: {
                diff,
                enrichData: coverageFuzzingFeedbacks,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveCoverageFuzzingError`', (done) => {
        mock.onGet('coverage_fuzzing_diff.json').reply(500);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'coverage_fuzzing',
            },
          })
          .reply(200, coverageFuzzingFeedbacks);

        testAction(
          fetchCoverageFuzzingDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestCoverageFuzzingDiff',
            },
            {
              type: 'receiveCoverageFuzzingDiffError',
            },
          ],
          done,
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveCoverageFuzzingError`', (done) => {
        mock.onGet('coverage_fuzzing_diff.json').reply(200, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'coverage_fuzzing',
            },
          })
          .reply(500);

        testAction(
          fetchCoverageFuzzingDiff,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestCoverageFuzzingDiff',
            },
            {
              type: 'receiveCoverageFuzzingDiffError',
            },
          ],
          done,
        );
      });
    });
  });
});
