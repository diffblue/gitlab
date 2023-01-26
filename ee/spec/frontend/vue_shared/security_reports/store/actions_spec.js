import MockAdapter from 'axios-mock-adapter';
import * as securityReportsAction from 'ee/vue_shared/security_reports/store/actions';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import state from 'ee/vue_shared/security_reports/store/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
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
    it('should commit set head blob path', async () => {
      await testAction(
        securityReportsAction.setHeadBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_HEAD_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
      );
    });
  });

  describe('setBaseBlobPath', () => {
    it('should commit set head blob path', async () => {
      await testAction(
        securityReportsAction.setBaseBlobPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_BASE_BLOB_PATH,
            payload: 'path',
          },
        ],
        [],
      );
    });
  });

  describe('setCanReadVulnerabilityFeedback', () => {
    it('should commit set vulnerabulity feedback path', async () => {
      await testAction(
        securityReportsAction.setCanReadVulnerabilityFeedback,
        true,
        mockedState,
        [
          {
            type: types.SET_CAN_READ_VULNERABILITY_FEEDBACK,
            payload: true,
          },
        ],
        [],
      );
    });
  });

  describe('setVulnerabilityFeedbackPath', () => {
    it('should commit set vulnerabulity feedback path', async () => {
      await testAction(
        securityReportsAction.setVulnerabilityFeedbackPath,
        'path',
        mockedState,
        [
          {
            type: types.SET_VULNERABILITY_FEEDBACK_PATH,
            payload: 'path',
          },
        ],
        [],
      );
    });
  });

  describe('setPipelineId', () => {
    it('should commit set vulnerability feedback path', async () => {
      await testAction(
        securityReportsAction.setPipelineId,
        123,
        mockedState,
        [
          {
            type: types.SET_PIPELINE_ID,
            payload: 123,
          },
        ],
        [],
      );
    });
  });

  describe('requestContainerScanningDiff', () => {
    it('should commit request mutation', async () => {
      await testAction(
        securityReportsAction.requestContainerScanningDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CONTAINER_SCANNING_DIFF,
          },
        ],
        [],
      );
    });
  });

  describe('requestDastDiff', () => {
    it('should commit request mutation', async () => {
      await testAction(
        securityReportsAction.requestDastDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DAST_DIFF,
          },
        ],
        [],
      );
    });
  });

  describe('requestDependencyScanningDiff', () => {
    it('should commit request mutation', async () => {
      await testAction(
        securityReportsAction.requestDependencyScanningDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DEPENDENCY_SCANNING_DIFF,
          },
        ],
        [],
      );
    });
  });

  describe('requestCoverageFuzzingDiff', () => {
    it('should commit request mutation', async () => {
      await testAction(
        securityReportsAction.requestCoverageFuzzingDiff,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_COVERAGE_FUZZING_DIFF,
          },
        ],
        [],
      );
    });
  });

  describe('setModalData', () => {
    it('commits set issue modal data', async () => {
      await testAction(
        securityReportsAction.setModalData,
        { issue: { id: 1 }, status: 'success' },
        mockedState,
        [
          {
            type: types.SET_ISSUE_MODAL_DATA,
            payload: { issue: { id: 1 }, status: 'success' },
          },
        ],
        [],
      );
    });
  });

  describe('requestDismissVulnerability', () => {
    it('commits request dismiss issue', async () => {
      await testAction(
        securityReportsAction.requestDismissVulnerability,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_DISMISS_VULNERABILITY,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDismissVulnerability', () => {
    it(`should pass the payload to the ${types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS} mutation`, async () => {
      const payload = createDismissedVulnerability();

      await testAction(
        securityReportsAction.receiveDismissVulnerability,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDismissVulnerabilityError', () => {
    it('commits receive dismiss issue error with payload', async () => {
      await testAction(
        securityReportsAction.receiveDismissVulnerabilityError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_DISMISS_VULNERABILITY_ERROR,
            payload: 'error',
          },
        ],
        [],
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
        mock.onPost('dismiss_vulnerability_path').reply(HTTP_STATUS_OK, dismissalFeedback);
        mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';
      });

      it(`should dispatch receiveDismissVulnerability`, async () => {
        await testAction(
          securityReportsAction.dismissVulnerability,
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
        );
      });

      it('show dismiss vulnerability toast message', async () => {
        await testAction(
          securityReportsAction.dismissVulnerability,
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
        );

        expect(toasted).toHaveBeenCalledTimes(1);
      });
    });

    describe.each`
      httpStatusErrorCode                  | expectedErrorMessage
      ${HTTP_STATUS_INTERNAL_SERVER_ERROR} | ${'There was an error dismissing the vulnerability. Please try again.'}
      ${HTTP_STATUS_UNPROCESSABLE_ENTITY}  | ${'Could not dismiss vulnerability because the associated pipeline no longer exists. Refresh the page and try again.'}
    `('with error "$httpStatusErrorCode"', ({ httpStatusErrorCode, expectedErrorMessage }) => {
      beforeEach(() => {
        mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';
        mockedState.canReadVulnerabilityFeedback = true;
      });

      it('should dispatch `receiveDismissVulnerabilityError` with the correct payload', async () => {
        mock
          .onPost(mockedState.createVulnerabilityFeedbackDismissalPath)
          .replyOnce(httpStatusErrorCode);

        await testAction(
          securityReportsAction.dismissVulnerability,
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
        mock.onPatch(url).replyOnce(HTTP_STATUS_OK, data);
      });

      it('should dispatch the request and success actions', async () => {
        await testAction(
          securityReportsAction.addDismissalComment,
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
        );
      });

      it('should show added dismissal comment toast message', async () => {
        await testAction(
          securityReportsAction.addDismissalComment,
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
        );

        expect(toasted).toHaveBeenCalledTimes(1);
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(HTTP_STATUS_NOT_FOUND);
      });

      it('should dispatch the request and error actions', async () => {
        await testAction(
          securityReportsAction.addDismissalComment,
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
        );
      });
    });

    describe('receiveAddDismissalCommentSuccess', () => {
      it('should commit the success mutation', async () => {
        await testAction(
          securityReportsAction.receiveAddDismissalCommentSuccess,
          { data },
          state,
          [{ type: types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload: { data } }],
          [],
        );
      });
    });

    describe('receiveAddDismissalCommentError', () => {
      it('should commit the error mutation', async () => {
        await testAction(
          securityReportsAction.receiveAddDismissalCommentError,
          {},
          state,
          [
            {
              type: types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR,
              payload: {},
            },
          ],
          [],
        );
      });
    });

    describe('requestAddDismissalComment', () => {
      it('should commit the request mutation', async () => {
        await testAction(
          securityReportsAction.requestAddDismissalComment,
          {},
          state,
          [{ type: types.REQUEST_ADD_DISMISSAL_COMMENT }],
          [],
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
        mock.onPatch(url).replyOnce(HTTP_STATUS_OK, data);
      });

      it('should dispatch the request and success actions', async () => {
        await testAction(
          securityReportsAction.deleteDismissalComment,
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
        );
      });

      it('should show deleted dismissal comment toast message', async () => {
        await testAction(
          securityReportsAction.deleteDismissalComment,
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
        );

        expect(toasted).toHaveBeenCalledTimes(1);
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onPatch(url).replyOnce(HTTP_STATUS_NOT_FOUND);
      });

      it('should dispatch the request and error actions', async () => {
        await testAction(
          securityReportsAction.deleteDismissalComment,
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
        );
      });
    });

    describe('receiveDeleteDismissalCommentSuccess', () => {
      it('should commit the success mutation', async () => {
        await testAction(
          securityReportsAction.receiveDeleteDismissalCommentSuccess,
          { data },
          state,
          [{ type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload: { data } }],
          [],
        );
      });
    });

    describe('receiveDeleteDismissalCommentError', () => {
      it('should commit the error mutation', async () => {
        await testAction(
          securityReportsAction.receiveDeleteDismissalCommentError,
          {},
          state,
          [
            {
              type: types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR,
              payload: {},
            },
          ],
          [],
        );
      });
    });

    describe('requestDeleteDismissalComment', () => {
      it('should commit the request mutation', async () => {
        await testAction(
          securityReportsAction.requestDeleteDismissalComment,
          {},
          state,
          [{ type: types.REQUEST_DELETE_DISMISSAL_COMMENT }],
          [],
        );
      });
    });
  });

  describe('showDismissalDeleteButtons', () => {
    it('commits show dismissal delete buttons', async () => {
      await testAction(
        securityReportsAction.showDismissalDeleteButtons,
        null,
        mockedState,
        [
          {
            type: types.SHOW_DISMISSAL_DELETE_BUTTONS,
          },
        ],
        [],
      );
    });
  });

  describe('hideDismissalDeleteButtons', () => {
    it('commits hide dismissal delete buttons', async () => {
      await testAction(
        securityReportsAction.hideDismissalDeleteButtons,
        null,
        mockedState,
        [
          {
            type: types.HIDE_DISMISSAL_DELETE_BUTTONS,
          },
        ],
        [],
      );
    });
  });

  describe('revertDismissVulnerability', () => {
    describe('with success', () => {
      let payload;

      beforeEach(() => {
        mock.onDelete('dismiss_vulnerability_path/123').reply(HTTP_STATUS_OK, {});
        mockedState.modal.vulnerability.dismissalFeedback = {
          id: 123,
          destroy_vulnerability_feedback_dismissal_path: 'dismiss_vulnerability_path/123',
        };
        payload = createNonDismissedVulnerability({ ...mockedState.modal.vulnerability });
      });

      it('should dispatch `receiveDismissVulnerability`', async () => {
        await testAction(
          securityReportsAction.revertDismissVulnerability,
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
        );
      });
    });

    it('with error should dispatch `receiveDismissVulnerabilityError`', async () => {
      mock.onDelete('dismiss_vulnerability_path/123').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
      mockedState.modal.vulnerability.dismissalFeedback = { id: 123 };
      mockedState.createVulnerabilityFeedbackDismissalPath = 'dismiss_vulnerability_path';

      await testAction(
        securityReportsAction.revertDismissVulnerability,
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
      );
    });
  });

  describe('requestCreateIssue', () => {
    it('commits request create issue', async () => {
      await testAction(
        securityReportsAction.requestCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CREATE_ISSUE,
          },
        ],
        [],
      );
    });
  });

  describe('receiveCreateIssue', () => {
    it('commits receive create issue', async () => {
      await testAction(
        securityReportsAction.receiveCreateIssue,
        null,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_SUCCESS,
          },
        ],
        [],
      );
    });
  });

  describe('receiveCreateIssueError', () => {
    it('commits receive create issue error with payload', async () => {
      await testAction(
        securityReportsAction.receiveCreateIssueError,
        'error',
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_ISSUE_ERROR,
            payload: 'error',
          },
        ],
        [],
      );
    });
  });

  describe('createNewIssue', () => {
    it('with success should dispatch `requestCreateIssue` and `receiveCreateIssue`', async () => {
      mock.onPost('create_issue_path').reply(HTTP_STATUS_OK, { issue_path: 'new_issue' });
      mockedState.createVulnerabilityFeedbackIssuePath = 'create_issue_path';

      await testAction(
        securityReportsAction.createNewIssue,
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
      );
    });

    it('with error should dispatch `receiveCreateIssueError`', async () => {
      mock.onPost('create_issue_path').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
      mockedState.vulnerabilityFeedbackPath = 'create_issue_path';
      mockedState.canReadVulnerabilityFeedback = true;

      await testAction(
        securityReportsAction.createNewIssue,
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
      );
    });
  });

  describe('downloadPatch', () => {
    it('creates a download link and clicks on it to download the file', () => {
      const a = { click: jest.fn() };
      jest.spyOn(document, 'createElement').mockImplementation(() => a);

      securityReportsAction.downloadPatch({
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
    it('commits request create merge request', async () => {
      await testAction(
        securityReportsAction.requestCreateMergeRequest,
        null,
        mockedState,
        [
          {
            type: types.REQUEST_CREATE_MERGE_REQUEST,
          },
        ],
        [],
      );
    });
  });

  describe('receiveCreateMergeRequestSuccess', () => {
    it('commits receive create merge request', async () => {
      const data = { foo: 'bar' };

      await testAction(
        securityReportsAction.receiveCreateMergeRequestSuccess,
        data,
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS,
            payload: data,
          },
        ],
        [],
      );
    });
  });

  describe('receiveCreateMergeRequestError', () => {
    it('commits receive create merge request error', async () => {
      await testAction(
        securityReportsAction.receiveCreateMergeRequestError,
        '',
        mockedState,
        [
          {
            type: types.RECEIVE_CREATE_MERGE_REQUEST_ERROR,
          },
        ],
        [],
      );
    });
  });

  describe('createMergeRequest', () => {
    it('with success should dispatch `receiveCreateMergeRequestSuccess`', async () => {
      const data = { merge_request_path: 'fakepath.html' };
      mockedState.createVulnerabilityFeedbackMergeRequestPath = 'create_merge_request_path';
      mock.onPost('create_merge_request_path').reply(HTTP_STATUS_OK, data);

      await testAction(
        securityReportsAction.createMergeRequest,
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
      );
    });

    it('with error should dispatch `receiveCreateMergeRequestError`', async () => {
      mock.onPost('create_merge_request_path').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});
      mockedState.vulnerabilityFeedbackPath = 'create_merge_request_path';
      mockedState.canReadVulnerabilityFeedback = true;

      await testAction(
        securityReportsAction.createMergeRequest,
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
      );
    });
  });

  describe('updateDependencyScanningIssue', () => {
    it('commits update dependency scanning issue', async () => {
      const payload = { foo: 'bar' };

      await testAction(
        securityReportsAction.updateDependencyScanningIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_DEPENDENCY_SCANNING_ISSUE,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('updateContainerScanningIssue', () => {
    it('commits update container scanning issue', async () => {
      const payload = { foo: 'bar' };

      await testAction(
        securityReportsAction.updateContainerScanningIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_CONTAINER_SCANNING_ISSUE,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('updateDastIssue', () => {
    it('commits update dast issue', async () => {
      const payload = { foo: 'bar' };

      await testAction(
        securityReportsAction.updateDastIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_DAST_ISSUE,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('updateCoverageFuzzingIssue', () => {
    it('commits update coverageFuzzing issue', async () => {
      const payload = { foo: 'bar' };

      await testAction(
        securityReportsAction.updateCoverageFuzzingIssue,
        payload,
        mockedState,
        [
          {
            type: types.UPDATE_COVERAGE_FUZZING_ISSUE,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('setContainerScanningDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', async () => {
      const payload = '/container_scanning_endpoint.json';

      await testAction(
        securityReportsAction.setContainerScanningDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_CONTAINER_SCANNING_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveContainerScanningDiffSuccess', () => {
    it('should pass down the response to the mutation', async () => {
      const payload = { data: 'Effort yields its own rewards.' };

      await testAction(
        securityReportsAction.receiveContainerScanningDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveContainerScanningDiffError', () => {
    it('should commit container diff error mutation', async () => {
      await testAction(
        securityReportsAction.receiveContainerScanningDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_CONTAINER_SCANNING_DIFF_ERROR,
          },
        ],
        [],
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
      it('should dispatch `receiveContainerScanningDiffSuccess`', async () => {
        mock.onGet(endpoint).reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(HTTP_STATUS_OK, containerScanningFeedbacks);

        await testAction(
          securityReportsAction.fetchContainerScanningDiff,
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
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        mockedState.canReadVulnerabilityFeedback = false;
        mock.onGet(endpoint).reply(HTTP_STATUS_OK, diff);
      });

      it('should dispatch `receiveContainerScanningDiffSuccess`', async () => {
        await testAction(
          securityReportsAction.fetchContainerScanningDiff,
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
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveContainerScanningError`', async () => {
        mock.onGet(endpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(HTTP_STATUS_OK, containerScanningFeedbacks);

        await testAction(
          securityReportsAction.fetchContainerScanningDiff,
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
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveContainerScanningError`', async () => {
        mock.onGet(endpoint).reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'container_scanning',
            },
          })
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await testAction(
          securityReportsAction.fetchContainerScanningDiff,
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
        );
      });
    });
  });

  describe('setDependencyScanningDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', async () => {
      const payload = '/dependency_scanning_endpoint.json';

      await testAction(
        securityReportsAction.setDependencyScanningDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDependencyScanningDiffSuccess', () => {
    it('should pass down the response to the mutation', async () => {
      const payload = { data: 'Effort yields its own rewards.' };

      await testAction(
        securityReportsAction.receiveDependencyScanningDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDependencyScanningDiffError', () => {
    it('should commit dependency scanning diff error mutation', async () => {
      await testAction(
        securityReportsAction.receiveDependencyScanningDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR,
          },
        ],
        [],
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
      it('should dispatch `receiveDependencyScanningDiffSuccess`', async () => {
        mock.onGet('dependency_scanning_diff.json').reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(HTTP_STATUS_OK, dependencyScanningFeedbacks);

        await testAction(
          securityReportsAction.fetchDependencyScanningDiff,
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
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        mockedState.canReadVulnerabilityFeedback = false;
        mock.onGet('dependency_scanning_diff.json').reply(HTTP_STATUS_OK, diff);
      });

      it('should dispatch `receiveDependencyScanningDiffSuccess`', async () => {
        await testAction(
          securityReportsAction.fetchDependencyScanningDiff,
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
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveDependencyScanningError`', async () => {
        mock.onGet('dependency_scanning_diff.json').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(HTTP_STATUS_OK, dependencyScanningFeedbacks);

        await testAction(
          securityReportsAction.fetchDependencyScanningDiff,
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
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveDependencyScanningError`', async () => {
        mock.onGet('dependency_scanning_diff.json').reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dependency_scanning',
            },
          })
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await testAction(
          securityReportsAction.fetchDependencyScanningDiff,
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
        );
      });
    });
  });

  describe('setDastDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', async () => {
      const payload = '/dast_endpoint.json';

      await testAction(
        securityReportsAction.setDastDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_DAST_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDastDiffSuccess', () => {
    it('should pass down the response to the mutation', async () => {
      const payload = { data: 'Effort yields its own rewards.' };

      await testAction(
        securityReportsAction.receiveDastDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveDastDiffError', () => {
    it('should commit dast diff error mutation', async () => {
      await testAction(
        securityReportsAction.receiveDastDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_DAST_DIFF_ERROR,
          },
        ],
        [],
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
      it('should dispatch `receiveDastDiffSuccess`', async () => {
        mock.onGet('dast_diff.json').reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(HTTP_STATUS_OK, dastFeedbacks);

        await testAction(
          securityReportsAction.fetchDastDiff,
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
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        mockedState.canReadVulnerabilityFeedback = false;
        mock.onGet('dast_diff.json').reply(HTTP_STATUS_OK, diff);
      });

      it('should dispatch `receiveDastDiffSuccess`', async () => {
        await testAction(
          securityReportsAction.fetchDastDiff,
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
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveDastError`', async () => {
        mock.onGet('dast_diff.json').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(HTTP_STATUS_OK, dastFeedbacks);

        await testAction(
          securityReportsAction.fetchDastDiff,
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
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveDastError`', async () => {
        mock.onGet('dast_diff.json').reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'dast',
            },
          })
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await testAction(
          securityReportsAction.fetchDastDiff,
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
        );
      });
    });
  });

  describe('setCoverageFuzzingDiffEndpoint', () => {
    it('should pass down the endpoint to the mutation', async () => {
      const payload = '/coverage_fuzzing_endpoint.json';

      await testAction(
        securityReportsAction.setCoverageFuzzingDiffEndpoint,
        payload,
        mockedState,
        [
          {
            type: types.SET_COVERAGE_FUZZING_DIFF_ENDPOINT,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveCoverageFuzzingDiffSuccess', () => {
    it('should pass down the response to the mutation', async () => {
      const payload = { data: 'Effort yields its own rewards.' };

      await testAction(
        securityReportsAction.receiveCoverageFuzzingDiffSuccess,
        payload,
        mockedState,
        [
          {
            type: types.RECEIVE_COVERAGE_FUZZING_DIFF_SUCCESS,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('receiveCoverageFuzzingDiffError', () => {
    it('should commit coverage fuzzing diff error mutation', async () => {
      await testAction(
        securityReportsAction.receiveCoverageFuzzingDiffError,
        undefined,
        mockedState,
        [
          {
            type: types.RECEIVE_COVERAGE_FUZZING_DIFF_ERROR,
          },
        ],
        [],
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
      it('should dispatch `receiveCoverageFuzzingDiffSuccess`', async () => {
        mock.onGet('coverage_fuzzing_diff.json').reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'coverage_fuzzing',
            },
          })
          .reply(HTTP_STATUS_OK, coverageFuzzingFeedbacks);

        await testAction(
          securityReportsAction.fetchCoverageFuzzingDiff,
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
        );
      });
    });

    describe('when vulnerabilities path errors', () => {
      it('should dispatch `receiveCoverageFuzzingError`', async () => {
        mock.onGet('coverage_fuzzing_diff.json').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'coverage_fuzzing',
            },
          })
          .reply(HTTP_STATUS_OK, coverageFuzzingFeedbacks);

        await testAction(
          securityReportsAction.fetchCoverageFuzzingDiff,
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
        );
      });
    });

    describe('when feedback path errors', () => {
      it('should dispatch `receiveCoverageFuzzingError`', async () => {
        mock.onGet('coverage_fuzzing_diff.json').reply(HTTP_STATUS_OK, diff);
        mock
          .onGet('vulnerabilities_feedback', {
            params: {
              category: 'coverage_fuzzing',
            },
          })
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await testAction(
          securityReportsAction.fetchCoverageFuzzingDiff,
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
        );
      });
    });
  });
});
