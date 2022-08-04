import * as Sentry from '@sentry/browser';
import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export default (mapStateToPayload, updateMethod = 'put') => ({
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

    return axios({
      method: updateMethod,
      url: endpoint,
      data: { ...mapStateToPayload(state) },
    })
      .then(({ data }) => {
        commit(types.UPDATE_SETTINGS_SUCCESS, data);
      })
      .catch((e) => {
        const error = e?.response?.data?.message || e;

        Sentry.captureException(error);
        commit(types.UPDATE_SETTINGS_ERROR);
      });
  },

  dismissErrorMessage({ commit }) {
    commit(types.DISMISS_ERROR_MESSAGE);
  },

  setPreventAuthorApproval({ commit }, value) {
    commit(types.SET_PREVENT_AUTHOR_APPROVAL, value);
  },

  setPreventCommittersApproval({ commit }, value) {
    commit(types.SET_PREVENT_COMMITTERS_APPROVAL, value);
  },

  setPreventMrApprovalRuleEdit({ commit }, value) {
    commit(types.SET_PREVENT_MR_APPROVAL_RULE_EDIT, value);
  },

  setRemoveApprovalsOnPush({ commit }, value) {
    commit(types.SET_REMOVE_APPROVALS_ON_PUSH, value);
  },

  setSelectiveCodeOwnerRemovals({ commit }, value) {
    commit(types.SET_SELECTIVE_CODE_OWNER_REMOVALS, value);
  },

  setRequireUserPassword({ commit }, value) {
    commit(types.SET_REQUIRE_USER_PASSWORD, value);
  },
});
