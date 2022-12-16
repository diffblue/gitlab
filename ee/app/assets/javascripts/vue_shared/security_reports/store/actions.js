import axios from '~/lib/utils/axios_utils';
import download from '~/lib/utils/downloader';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import {
  FEEDBACK_TYPE_DISMISSAL,
  FEEDBACK_TYPE_ISSUE,
  FEEDBACK_TYPE_MERGE_REQUEST,
} from '~/vue_shared/security_reports/constants';
import { fetchDiffData } from '~/vue_shared/security_reports/store/utils';
import * as types from './mutation_types';

/**
 * A lot of this file has duplicate actions to
 * ee/app/assets/javascripts/security_dashboard/store/modules/vulnerabilities/actions.js
 * This is being addressed in the following issues:
 *
 * https://gitlab.com/gitlab-org/gitlab/issues/8146
 * https://gitlab.com/gitlab-org/gitlab/issues/8519
 */

export const setHeadBlobPath = ({ commit }, blobPath) => commit(types.SET_HEAD_BLOB_PATH, blobPath);

export const setBaseBlobPath = ({ commit }, blobPath) => commit(types.SET_BASE_BLOB_PATH, blobPath);

export const setSourceBranch = ({ commit }, branch) => commit(types.SET_SOURCE_BRANCH, branch);

export const setCanReadVulnerabilityFeedback = ({ commit }, value) =>
  commit(types.SET_CAN_READ_VULNERABILITY_FEEDBACK, value);

export const setVulnerabilityFeedbackPath = ({ commit }, path) =>
  commit(types.SET_VULNERABILITY_FEEDBACK_PATH, path);

export const setCreateVulnerabilityFeedbackIssuePath = ({ commit }, path) =>
  commit(types.SET_CREATE_VULNERABILITY_FEEDBACK_ISSUE_PATH, path);

export const setCreateVulnerabilityFeedbackMergeRequestPath = ({ commit }, path) =>
  commit(types.SET_CREATE_VULNERABILITY_FEEDBACK_MERGE_REQUEST_PATH, path);

export const setCreateVulnerabilityFeedbackDismissalPath = ({ commit }, path) =>
  commit(types.SET_CREATE_VULNERABILITY_FEEDBACK_DISMISSAL_PATH, path);

export const setPipelineId = ({ commit }, id) => commit(types.SET_PIPELINE_ID, id);

/**
 * CONTAINER SCANNING
 */

export const setContainerScanningDiffEndpoint = ({ commit }, path) =>
  commit(types.SET_CONTAINER_SCANNING_DIFF_ENDPOINT, path);

export const requestContainerScanningDiff = ({ commit }) =>
  commit(types.REQUEST_CONTAINER_SCANNING_DIFF);

export const receiveContainerScanningDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS, response);

export const receiveContainerScanningDiffError = ({ commit }) =>
  commit(types.RECEIVE_CONTAINER_SCANNING_DIFF_ERROR);

export const fetchContainerScanningDiff = ({ state, dispatch }) => {
  dispatch('requestContainerScanningDiff');

  return fetchDiffData(state, state.containerScanning.paths.diffEndpoint, 'container_scanning')
    .then((data) => {
      dispatch('receiveContainerScanningDiffSuccess', data);
      return data;
    })
    .catch(() => {
      dispatch('receiveContainerScanningDiffError');
    });
};

export const updateContainerScanningIssue = ({ commit }, issue) =>
  commit(types.UPDATE_CONTAINER_SCANNING_ISSUE, issue);

/**
 * DAST
 */
export const setDastDiffEndpoint = ({ commit }, path) => commit(types.SET_DAST_DIFF_ENDPOINT, path);

export const requestDastDiff = ({ commit }) => commit(types.REQUEST_DAST_DIFF);

export const updateDastIssue = ({ commit }, issue) => commit(types.UPDATE_DAST_ISSUE, issue);

export const receiveDastDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_DAST_DIFF_SUCCESS, response);

export const receiveDastDiffError = ({ commit }) => commit(types.RECEIVE_DAST_DIFF_ERROR);

export const fetchDastDiff = ({ state, dispatch }) => {
  dispatch('requestDastDiff');

  return fetchDiffData(state, state.dast.paths.diffEndpoint, 'dast')
    .then((data) => {
      dispatch('receiveDastDiffSuccess', data);
      return data;
    })
    .catch(() => {
      dispatch('receiveDastDiffError');
    });
};

/**
 * DEPENDENCY SCANNING
 */

export const setDependencyScanningDiffEndpoint = ({ commit }, path) =>
  commit(types.SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT, path);

export const requestDependencyScanningDiff = ({ commit }) =>
  commit(types.REQUEST_DEPENDENCY_SCANNING_DIFF);

export const receiveDependencyScanningDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS, response);

export const receiveDependencyScanningDiffError = ({ commit }) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR);

export const fetchDependencyScanningDiff = ({ state, dispatch }) => {
  dispatch('requestDependencyScanningDiff');

  return fetchDiffData(state, state.dependencyScanning.paths.diffEndpoint, 'dependency_scanning')
    .then((data) => {
      dispatch('receiveDependencyScanningDiffSuccess', data);
      return data;
    })
    .catch(() => {
      dispatch('receiveDependencyScanningDiffError');
    });
};

export const updateDependencyScanningIssue = ({ commit }, issue) =>
  commit(types.UPDATE_DEPENDENCY_SCANNING_ISSUE, issue);

/**
 * COVERAGE FUZZING
 */
export const setCoverageFuzzingDiffEndpoint = ({ commit }, path) =>
  commit(types.SET_COVERAGE_FUZZING_DIFF_ENDPOINT, path);

export const requestCoverageFuzzingDiff = ({ commit }) =>
  commit(types.REQUEST_COVERAGE_FUZZING_DIFF);

export const receiveCoverageFuzzingDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_COVERAGE_FUZZING_DIFF_SUCCESS, response);

export const receiveCoverageFuzzingDiffError = ({ commit }) =>
  commit(types.RECEIVE_COVERAGE_FUZZING_DIFF_ERROR);

export const fetchCoverageFuzzingDiff = ({ state, dispatch }) => {
  dispatch('requestCoverageFuzzingDiff');

  return Promise.all([
    pollUntilComplete(state.coverageFuzzing.paths.diffEndpoint),
    axios.get(state.vulnerabilityFeedbackPath, {
      params: {
        category: 'coverage_fuzzing',
      },
    }),
  ])
    .then((values) => {
      const data = {
        diff: values[0].data,
        enrichData: values[1].data,
      };

      dispatch('receiveCoverageFuzzingDiffSuccess', data);
      return data;
    })
    .catch(() => {
      dispatch('receiveCoverageFuzzingDiffError');
    });
};

export const updateCoverageFuzzingIssue = ({ commit }, issue) =>
  commit(types.UPDATE_COVERAGE_FUZZING_ISSUE, issue);

export const setModalData = ({ commit }, payload) => commit(types.SET_ISSUE_MODAL_DATA, payload);
export const requestDismissVulnerability = ({ commit }) =>
  commit(types.REQUEST_DISMISS_VULNERABILITY);
export const receiveDismissVulnerability = ({ commit }, payload) =>
  commit(types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS, payload);
export const receiveDismissVulnerabilityError = ({ commit }, error) =>
  commit(types.RECEIVE_DISMISS_VULNERABILITY_ERROR, error);

export const dismissVulnerability = ({ state, dispatch }, comment) => {
  dispatch('requestDismissVulnerability');

  const toastMsg = sprintf(s__("SecurityReports|Dismissed '%{vulnerabilityName}'"), {
    vulnerabilityName: state.modal.vulnerability.name,
  });

  return axios
    .post(state.createVulnerabilityFeedbackDismissalPath, {
      vulnerability_feedback: {
        category: state.modal.vulnerability.category,
        comment,
        feedback_type: FEEDBACK_TYPE_DISMISSAL,
        pipeline_id: state.pipelineId,
        project_fingerprint: state.modal.vulnerability.project_fingerprint,
        finding_uuid: state.modal.vulnerability.uuid,
        vulnerability_data: state.modal.vulnerability,
      },
    })
    .then(({ data }) => {
      const updatedIssue = {
        ...state.modal.vulnerability,
        isDismissed: true,
        dismissalFeedback: data,
      };

      dispatch('closeDismissalCommentBox');
      dispatch('receiveDismissVulnerability', updatedIssue);
      toast(toastMsg);
    })
    .catch((error) => {
      const pipelineNoLongerExists = error.response?.status === HTTP_STATUS_UNPROCESSABLE_ENTITY;
      const errorMessage = pipelineNoLongerExists
        ? s__(
            'ciReport|Could not dismiss vulnerability because the associated pipeline no longer exists. Refresh the page and try again.',
          )
        : s__('ciReport|There was an error dismissing the vulnerability. Please try again.');

      dispatch('receiveDismissVulnerabilityError', errorMessage);
    });
};

export const addDismissalComment = ({ state, dispatch }, { comment }) => {
  dispatch('requestAddDismissalComment');

  const { vulnerability } = state.modal;
  const { dismissalFeedback } = vulnerability;
  const url = `${state.createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`;

  const editingDismissalContent =
    dismissalFeedback.comment_details && dismissalFeedback.comment_details.comment;

  const toastMsg = editingDismissalContent
    ? sprintf(s__("SecurityReports|Comment edited on '%{vulnerabilityName}'"), {
        vulnerabilityName: vulnerability.name,
      })
    : sprintf(s__("SecurityReports|Comment added to '%{vulnerabilityName}'"), {
        vulnerabilityName: vulnerability.name,
      });

  return axios
    .patch(url, {
      project_id: dismissalFeedback.project_id,
      id: dismissalFeedback.id,
      comment,
    })
    .then(({ data }) => {
      dispatch('closeDismissalCommentBox');
      dispatch('receiveAddDismissalCommentSuccess', { data });
      toast(toastMsg);
    })
    .catch(() => {
      dispatch(
        'receiveAddDismissalCommentError',
        s__('SecurityReports|There was an error adding the comment.'),
      );
    });
};

export const deleteDismissalComment = ({ state, dispatch }) => {
  dispatch('requestDeleteDismissalComment');

  const { vulnerability } = state.modal;
  const { dismissalFeedback } = vulnerability;
  const url = `${state.createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`;
  const toastMsg = sprintf(s__("SecurityReports|Comment deleted on '%{vulnerabilityName}'"), {
    vulnerabilityName: vulnerability.name,
  });

  return axios
    .patch(url, {
      project_id: dismissalFeedback.project_id,
      comment: '',
    })
    .then(({ data }) => {
      dispatch('closeDismissalCommentBox');
      dispatch('receiveDeleteDismissalCommentSuccess', { data });
      toast(toastMsg);
    })
    .catch(() => {
      dispatch(
        'receiveDeleteDismissalCommentError',
        s__('SecurityReports|There was an error deleting the comment.'),
      );
    });
};

export const requestDeleteDismissalComment = ({ commit }) => {
  commit(types.REQUEST_DELETE_DISMISSAL_COMMENT);
};

export const receiveDeleteDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload);
};

export const receiveDeleteDismissalCommentError = ({ commit }, error) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR, error);
};

export const requestAddDismissalComment = ({ commit }) => {
  commit(types.REQUEST_ADD_DISMISSAL_COMMENT);
};

export const receiveAddDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload);
};

export const receiveAddDismissalCommentError = ({ commit }, error) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR, error);
};

export const revertDismissVulnerability = ({ state, dispatch }) => {
  dispatch('requestDismissVulnerability');

  return axios
    .delete(
      state.modal.vulnerability.dismissalFeedback.destroy_vulnerability_feedback_dismissal_path,
    )
    .then(() => {
      const updatedIssue = {
        ...state.modal.vulnerability,
        isDismissed: false,
        dismissalFeedback: null,
        dismissal_feedback: null,
      };

      dispatch('receiveDismissVulnerability', updatedIssue);
    })
    .catch(() =>
      dispatch(
        'receiveDismissVulnerabilityError',
        s__('ciReport|There was an error reverting the dismissal. Please try again.'),
      ),
    );
};

export const showDismissalDeleteButtons = ({ commit }) => {
  commit(types.SHOW_DISMISSAL_DELETE_BUTTONS);
};

export const hideDismissalDeleteButtons = ({ commit }) => {
  commit(types.HIDE_DISMISSAL_DELETE_BUTTONS);
};

export const requestCreateIssue = ({ commit }) => commit(types.REQUEST_CREATE_ISSUE);
export const receiveCreateIssue = ({ commit }) => commit(types.RECEIVE_CREATE_ISSUE_SUCCESS);
export const receiveCreateIssueError = ({ commit }, error) =>
  commit(types.RECEIVE_CREATE_ISSUE_ERROR, error);

export const createNewIssue = ({ state, dispatch }) => {
  dispatch('requestCreateIssue');

  axios
    .post(state.createVulnerabilityFeedbackIssuePath, {
      vulnerability_feedback: {
        feedback_type: FEEDBACK_TYPE_ISSUE,
        category: state.modal.vulnerability.category,
        project_fingerprint: state.modal.vulnerability.project_fingerprint,
        finding_uuid: state.modal.vulnerability.uuid,
        pipeline_id: state.pipelineId,
        vulnerability_data: state.modal.vulnerability,
      },
    })
    .then((response) => {
      dispatch('receiveCreateIssue');
      // redirect the user to the created issue
      visitUrl(response.data.issue_url);
    })
    .catch(() =>
      dispatch(
        'receiveCreateIssueError',
        s__('ciReport|There was an error creating the issue. Please try again.'),
      ),
    );
};

export const createMergeRequest = ({ state, dispatch }) => {
  const { vulnerability } = state.modal;
  const { category, project_fingerprint } = vulnerability;

  vulnerability.target_branch = state.sourceBranch;

  dispatch('requestCreateMergeRequest');

  axios
    .post(state.createVulnerabilityFeedbackMergeRequestPath, {
      vulnerability_feedback: {
        feedback_type: FEEDBACK_TYPE_MERGE_REQUEST,
        category,
        project_fingerprint,
        finding_uuid: vulnerability.uuid,
        vulnerability_data: vulnerability,
      },
    })
    .then(({ data }) => {
      dispatch('receiveCreateMergeRequestSuccess', data);
    })
    .catch(() => {
      dispatch(
        'receiveCreateMergeRequestError',
        s__('ciReport|There was an error creating the merge request. Please try again.'),
      );
    });
};

export const downloadPatch = ({ state }) => {
  /*
    This action doesn't actually mutate the Vuex state and is a dirty
    workaround to modifying the dom. We do this because gl-split-button
    relies on a old version of vue-bootstrap and it doesn't allow us to
    set a href for a file download.

    https://gitlab.com/gitlab-org/gitlab-ui/issues/188#note_165808493
  */
  const { vulnerability } = state.modal;
  download({ fileData: vulnerability.remediations[0].diff, fileName: 'remediation.patch' });
};

export const requestCreateMergeRequest = ({ commit }) => {
  commit(types.REQUEST_CREATE_MERGE_REQUEST);
};

export const receiveCreateMergeRequestSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS, payload);
};

export const receiveCreateMergeRequestError = ({ commit }) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_ERROR);
};

export const openDismissalCommentBox = ({ commit }) => {
  commit(types.OPEN_DISMISSAL_COMMENT_BOX);
};

export const closeDismissalCommentBox = ({ commit }) => {
  commit(types.CLOSE_DISMISSAL_COMMENT_BOX);
};
