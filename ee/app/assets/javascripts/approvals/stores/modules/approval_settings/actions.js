import * as Sentry from '@sentry/browser';
import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export default (mapStateToPayload) => ({
  fetchSettings({ commit }, endpoint) {
    commit(types.REQUEST_SETTINGS);

    return axios
      .get(endpoint)
      .then(({ data }) => {
        commit(types.RECEIVE_SETTINGS_SUCCESS, data);
      })
      .catch((e) => {
        const error = e?.response?.data?.message || e;

        Sentry.captureException(error);
        commit(types.RECEIVE_SETTINGS_ERROR);
      });
  },

  updateSettings({ commit, state }, endpoint) {
    commit(types.REQUEST_UPDATE_SETTINGS);

    return axios
      .put(endpoint, { ...mapStateToPayload(state) })
      .then(({ data }) => {
        commit(types.UPDATE_SETTINGS_SUCCESS, data);
      })
      .catch((e) => {
        const error = e?.response?.data?.message || e;

        Sentry.captureException(error);
        commit(types.UPDATE_SETTINGS_ERROR);
      });
  },

  dismissSuccessMessage({ commit }) {
    commit(types.DISMISS_SUCCESS_MESSAGE);
  },

  dismissErrorMessage({ commit }) {
    commit(types.DISMISS_ERROR_MESSAGE);
  },

  setPreventAuthorApproval({ commit }, { preventAuthorApproval }) {
    commit(types.SET_PREVENT_AUTHOR_APPROVAL, preventAuthorApproval);
  },

  setPreventCommittersApproval({ commit }, { preventCommittersApproval }) {
    commit(types.SET_PREVENT_COMMITTERS_APPROVAL, preventCommittersApproval);
  },

  setPreventMrApprovalRuleEdit({ commit }, { preventMrApprovalRuleEdit }) {
    commit(types.SET_PREVENT_MR_APPROVAL_RULE_EDIT, preventMrApprovalRuleEdit);
  },

  setRemoveApprovalsOnPush({ commit }, { removeApprovalsOnPush }) {
    commit(types.SET_REMOVE_APPROVALS_ON_PUSH, removeApprovalsOnPush);
  },

  setRequireUserPassword({ commit }, { requireUserPassword }) {
    commit(types.SET_REQUIRE_USER_PASSWORD, requireUserPassword);
  },
});
