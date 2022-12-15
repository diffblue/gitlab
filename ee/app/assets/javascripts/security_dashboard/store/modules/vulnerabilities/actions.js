import _ from 'lodash';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import {
  parseIntPagination,
  normalizeHeaders,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import download from '~/lib/utils/downloader';
import { s__, n__, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import {
  FEEDBACK_TYPE_DISMISSAL,
  FEEDBACK_TYPE_ISSUE,
  FEEDBACK_TYPE_MERGE_REQUEST,
} from '~/vue_shared/security_reports/constants';
import { DISMISSAL_STATES } from 'ee/security_dashboard/store/modules/filters/constants';
import * as types from './mutation_types';

let vulnerabilitiesSource;

/**
 * A lot of this file has duplicate actions in
 * ee/app/assets/javascripts/vue_shared/security_reports/store/actions.js
 * This is being addressed in the following issues:
 *
 * https://gitlab.com/gitlab-org/gitlab/issues/8146
 * https://gitlab.com/gitlab-org/gitlab/issues/8519
 */

export const setPipelineId = ({ commit }, id) => commit(types.SET_PIPELINE_ID, id);

export const setSourceBranch = ({ commit }, ref) => commit(types.SET_SOURCE_BRANCH, ref);

export const setVulnerabilitiesEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_VULNERABILITIES_ENDPOINT, endpoint);
};

export const setVulnerabilitiesPage = ({ commit }, page) => {
  commit(types.SET_VULNERABILITIES_PAGE, page);
};

export const fetchVulnerabilities = ({ state, dispatch }, params = {}) => {
  if (!state.vulnerabilitiesEndpoint) {
    return;
  }
  dispatch('requestVulnerabilities');
  // Cancel a pending request if there is one.
  if (vulnerabilitiesSource) {
    vulnerabilitiesSource.cancel();
  }

  vulnerabilitiesSource = axios.CancelToken.source();

  axios({
    method: 'GET',
    url: state.vulnerabilitiesEndpoint,
    cancelToken: vulnerabilitiesSource.token,
    params,
  })
    .then((response) => {
      const { headers, data } = response;
      dispatch('receiveVulnerabilitiesSuccess', { headers, data });
    })
    .catch((error) => {
      // Don't show an error message if the request was cancelled through the cancel token.
      if (!axios.isCancel(error)) {
        dispatch('receiveVulnerabilitiesError', error?.response?.status);
      }
    });
};

export const requestVulnerabilities = ({ commit }) => {
  commit(types.REQUEST_VULNERABILITIES);
};

export const receiveVulnerabilitiesSuccess = ({ commit }, { headers, data }) => {
  const normalizedHeaders = normalizeHeaders(headers);
  const pageInfo = parseIntPagination(normalizedHeaders);

  const vulnerabilities = data.map((vulnerability) => ({
    ...vulnerability,
    // Vulnerabilities on pipelines don't have IDs.
    // We need to add dummy IDs here to avoid rendering issues.
    id: vulnerability.id || _.uniqueId('client_'),
    // The generic report component expects all fields within `vulnerability.details` to be in camelCase
    ...(vulnerability.details && {
      details: convertObjectPropsToCamelCase(vulnerability.details, { deep: true }),
    }),
  }));

  commit(types.RECEIVE_VULNERABILITIES_SUCCESS, { pageInfo, vulnerabilities });
};

export const receiveVulnerabilitiesError = ({ commit }, errorCode) => {
  commit(types.RECEIVE_VULNERABILITIES_ERROR, errorCode);
};

export const setModalData = ({ commit }, payload = {}) => {
  commit(types.SET_MODAL_DATA, payload);
};

export const createIssue = ({ dispatch }, { vulnerability, flashError }) => {
  dispatch('requestCreateIssue');
  axios
    .post(vulnerability.create_vulnerability_feedback_issue_path, {
      vulnerability_feedback: {
        feedback_type: FEEDBACK_TYPE_ISSUE,
        category: vulnerability.report_type,
        project_fingerprint: vulnerability.project_fingerprint,
        finding_uuid: vulnerability.uuid,
        vulnerability_data: {
          ...vulnerability,
          category: vulnerability.report_type,
        },
      },
    })
    .then(({ data }) => {
      dispatch('receiveCreateIssueSuccess', data);
    })
    .catch(() => {
      dispatch('receiveCreateIssueError', { flashError });
    });
};

export const requestCreateIssue = ({ commit }) => {
  commit(types.REQUEST_CREATE_ISSUE);
};

export const receiveCreateIssueSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_CREATE_ISSUE_SUCCESS, payload);
};

export const receiveCreateIssueError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_CREATE_ISSUE_ERROR);

  if (flashError) {
    createAlert({
      message: s__('SecurityReports|There was an error creating the issue.'),
      parent: document.querySelector('.ci-table'),
    });
  }
};

export const selectAllVulnerabilities = ({ commit }) => {
  commit(types.SELECT_ALL_VULNERABILITIES);
};

export const deselectAllVulnerabilities = ({ commit }) => {
  commit(types.DESELECT_ALL_VULNERABILITIES);
};

export const selectVulnerability = ({ commit }, { id }) => {
  commit(types.SELECT_VULNERABILITY, id);
};

export const deselectVulnerability = ({ commit }, { id }) => {
  commit(types.DESELECT_VULNERABILITY, id);
};

export const dismissSelectedVulnerabilities = (
  { dispatch, state, rootState },
  { comment } = {},
) => {
  const { filters } = rootState.filters;
  const { vulnerabilities, selectedVulnerabilities, pageInfo } = state;
  const dismissableVulnerabilties = vulnerabilities.filter(({ id }) => selectedVulnerabilities[id]);

  const currentPage = pageInfo?.page || 1;
  const vulnerabilitiesOnPage = vulnerabilities.length - dismissableVulnerabilties.length;
  const hideDismissed = filters?.scope === DISMISSAL_STATES.DISMISSED;
  const shouldLoadPreviousPage = hideDismissed && vulnerabilitiesOnPage < 1;

  dispatch('requestDismissSelectedVulnerabilities');

  const promises = dismissableVulnerabilties.map((vulnerability) =>
    axios.post(vulnerability.create_vulnerability_feedback_dismissal_path, {
      vulnerability_feedback: {
        category: vulnerability.report_type,
        comment,
        feedback_type: FEEDBACK_TYPE_DISMISSAL,
        project_fingerprint: vulnerability.project_fingerprint,
        finding_uuid: vulnerability.uuid,
        vulnerability_data: {
          id: vulnerability.id,
        },
      },
    }),
  );

  return Promise.all(promises)
    .then(() => {
      dispatch('receiveDismissSelectedVulnerabilitiesSuccess');
      dispatch('fetchVulnerabilities', {
        ...filters,
        page: shouldLoadPreviousPage ? currentPage - 1 : currentPage,
      });
    })
    .catch(() => {
      dispatch('receiveDismissSelectedVulnerabilitiesError', { flashError: true });
    });
};

export const requestDismissSelectedVulnerabilities = ({ commit }) => {
  commit(types.REQUEST_DISMISS_SELECTED_VULNERABILITIES);
};

export const receiveDismissSelectedVulnerabilitiesSuccess = ({ commit, getters }) => {
  toast(
    n__(
      '%d vulnerability dismissed',
      '%d vulnerabilities dismissed',
      getters.selectedVulnerabilitiesCount,
    ),
  );
  commit(types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_SUCCESS);
};

export const receiveDismissSelectedVulnerabilitiesError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_DISMISS_SELECTED_VULNERABILITIES_ERROR);
  if (flashError) {
    createAlert({
      message: s__('SecurityReports|There was an error dismissing the vulnerabilities.'),
      parent: document.querySelector('.ci-table'),
    });
  }
};

export const dismissVulnerability = (
  { dispatch, state, rootState },
  { vulnerability, flashError, comment },
) => {
  const page = state.pageInfo && state.pageInfo.page ? state.pageInfo.page : 1;
  const dismissedVulnerabilitiesHidden = Boolean(
    rootState.filters && rootState.filters.hideDismissed,
  );
  dispatch('requestDismissVulnerability');

  const toastMsg = sprintf(
    dismissedVulnerabilitiesHidden
      ? s__(
          "SecurityReports|Dismissed '%{vulnerabilityName}'. Turn off the hide dismissed toggle to view.",
        )
      : s__("SecurityReports|Dismissed '%{vulnerabilityName}'"),
    {
      vulnerabilityName: vulnerability.name,
    },
  );
  const toastOptions = dismissedVulnerabilitiesHidden
    ? {
        action: {
          text: s__('SecurityReports|Undo dismiss'),
          onClick: (e, toastObject) => {
            if (vulnerability.dismissal_feedback) {
              dispatch('revertDismissVulnerability', { vulnerability })
                .then(() => dispatch('fetchVulnerabilities', { page }))
                .catch(() => {});
              toastObject.hide();
            }
          },
        },
      }
    : {};

  return axios
    .post(vulnerability.create_vulnerability_feedback_dismissal_path, {
      vulnerability_feedback: {
        category: vulnerability.report_type,
        comment,
        feedback_type: FEEDBACK_TYPE_DISMISSAL,
        pipeline_id: state.pipelineId,
        project_fingerprint: vulnerability.project_fingerprint,
        finding_uuid: vulnerability.uuid,
        vulnerability_data: {
          ...vulnerability,
          category: vulnerability.report_type,
        },
      },
    })
    .then(({ data }) => {
      dispatch('closeDismissalCommentBox');
      dispatch('receiveDismissVulnerabilitySuccess', { vulnerability, data });
      if (dismissedVulnerabilitiesHidden) {
        dispatch('fetchVulnerabilities', {
          // If we just dismissed the last vulnerability on the active page,
          // we load the previous page if any
          page: state.vulnerabilities.length === 1 && page > 1 ? page - 1 : page,
        });
      }
      toast(toastMsg, toastOptions);
    })
    .catch(() => {
      dispatch('receiveDismissVulnerabilityError', { flashError });
    });
};

export const requestDismissVulnerability = ({ commit }) => {
  commit(types.REQUEST_DISMISS_VULNERABILITY);
};

export const receiveDismissVulnerabilitySuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS, payload);
};

export const receiveDismissVulnerabilityError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_DISMISS_VULNERABILITY_ERROR);
  if (flashError) {
    createAlert({
      message: s__('SecurityReports|There was an error dismissing the vulnerability.'),
      parent: document.querySelector('.ci-table'),
    });
  }
};

export const addDismissalComment = ({ dispatch }, { vulnerability, comment }) => {
  dispatch('requestAddDismissalComment');
  const { dismissal_feedback: dismissalFeedback } = vulnerability;
  const url = `${vulnerability.create_vulnerability_feedback_dismissal_path}/${dismissalFeedback.id}`;

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
      dispatch('receiveAddDismissalCommentSuccess', { vulnerability, data });
      toast(toastMsg);
    })
    .catch(() => {
      dispatch('receiveAddDismissalCommentError');
    });
};

export const deleteDismissalComment = ({ dispatch }, { vulnerability }) => {
  dispatch('requestDeleteDismissalComment');

  const { dismissal_feedback: dismissalFeedback } = vulnerability;
  const url = `${vulnerability.create_vulnerability_feedback_dismissal_path}/${dismissalFeedback.id}`;
  const toastMsg = sprintf(s__("SecurityReports|Comment deleted on '%{vulnerabilityName}'"), {
    vulnerabilityName: vulnerability.name,
  });

  return axios
    .patch(url, {
      project_id: dismissalFeedback.project_id,
      comment: '',
    })
    .then(({ data }) => {
      const { id } = vulnerability;
      dispatch('closeDismissalCommentBox');
      dispatch('receiveDeleteDismissalCommentSuccess', { id, data });
      toast(toastMsg);
    })
    .catch(() => {
      dispatch('receiveDeleteDismissalCommentError');
    });
};

export const requestAddDismissalComment = ({ commit }) => {
  commit(types.REQUEST_ADD_DISMISSAL_COMMENT);
};

export const receiveAddDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload);
};

export const receiveAddDismissalCommentError = ({ commit }) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR);
};

export const requestDeleteDismissalComment = ({ commit }) => {
  commit(types.REQUEST_DELETE_DISMISSAL_COMMENT);
};

export const receiveDeleteDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload);
};

export const receiveDeleteDismissalCommentError = ({ commit }) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR);
};

export const showDismissalDeleteButtons = ({ commit }) => {
  commit(types.SHOW_DISMISSAL_DELETE_BUTTONS);
};

export const hideDismissalDeleteButtons = ({ commit }) => {
  commit(types.HIDE_DISMISSAL_DELETE_BUTTONS);
};

export const revertDismissVulnerability = ({ dispatch }, { vulnerability, flashError }) => {
  const { destroy_vulnerability_feedback_dismissal_path } = vulnerability.dismissal_feedback;

  dispatch('requestUndoDismiss');

  return axios
    .delete(destroy_vulnerability_feedback_dismissal_path)
    .then(() => {
      dispatch('receiveUndoDismissSuccess', { vulnerability });
    })
    .catch(() => {
      dispatch('receiveUndoDismissError', { flashError });
    });
};

export const requestUndoDismiss = ({ commit }) => {
  commit(types.REQUEST_REVERT_DISMISSAL);
};

export const receiveUndoDismissSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_REVERT_DISMISSAL_SUCCESS, payload);
};

export const receiveUndoDismissError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_REVERT_DISMISSAL_ERROR);
  if (flashError) {
    createAlert({
      message: s__('SecurityReports|There was an error reverting this dismissal.'),
      parent: document.querySelector('.ci-table'),
    });
  }
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
  download({ fileData: vulnerability.remediations[0].diff, fileName: `remediation.patch` });
};

export const createMergeRequest = ({ state, dispatch }, { vulnerability, flashError }) => {
  const {
    report_type: category,
    project_fingerprint,
    create_vulnerability_feedback_merge_request_path,
  } = vulnerability;

  // The target branch for the MR is the source branch of the pipeline.
  // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23677#note_278221556
  const targetBranch = state.sourceBranch;

  dispatch('requestCreateMergeRequest');

  axios
    .post(create_vulnerability_feedback_merge_request_path, {
      vulnerability_feedback: {
        feedback_type: FEEDBACK_TYPE_MERGE_REQUEST,
        category,
        project_fingerprint,
        finding_uuid: vulnerability.uuid,
        vulnerability_data: {
          ...vulnerability,
          target_branch: targetBranch,
          category,
        },
      },
    })
    .then(({ data }) => {
      dispatch('receiveCreateMergeRequestSuccess', data);
    })
    .catch(() => {
      dispatch('receiveCreateMergeRequestError', { flashError });
    });
};

export const requestCreateMergeRequest = ({ commit }) => {
  commit(types.REQUEST_CREATE_MERGE_REQUEST);
};

export const receiveCreateMergeRequestSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS, payload);
};

export const receiveCreateMergeRequestError = ({ commit }, { flashError }) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_ERROR);

  if (flashError) {
    createAlert({
      message: s__('SecurityReports|There was an error creating the merge request.'),
      parent: document.querySelector('.ci-table'),
    });
  }
};

export const openDismissalCommentBox = ({ commit }) => {
  commit(types.OPEN_DISMISSAL_COMMENT_BOX);
};

export const closeDismissalCommentBox = ({ commit }) => {
  commit(types.CLOSE_DISMISSAL_COMMENT_BOX);
};
