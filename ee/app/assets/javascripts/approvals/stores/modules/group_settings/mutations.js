import { APPROVAL_SETTINGS_I18N } from '../../../constants';
import * as types from './mutation_types';

const mapDataToState = (data) => ({
  preventAuthorApproval: !data.allow_author_approval,
  preventMrApprovalRuleEdit: !data.allow_overrides_to_approver_list_per_merge_request,
  requireUserPassword: data.require_password_to_approve,
  removeApprovalsOnPush: !data.retain_approvals_on_push,
  preventCommittersApproval: !data.allow_committer_approval,
});

export default {
  [types.REQUEST_SETTINGS](state) {
    state.isLoading = true;
    state.errorMessage = '';
  },
  [types.RECEIVE_SETTINGS_SUCCESS](state, data) {
    state.settings = { ...mapDataToState(data) };
    state.isLoading = false;
  },
  [types.RECEIVE_SETTINGS_ERROR](state) {
    state.isLoading = false;
    state.errorMessage = APPROVAL_SETTINGS_I18N.loadingErrorMessage;
  },
  [types.REQUEST_UPDATE_SETTINGS](state) {
    state.isLoading = true;
    state.isUpdated = false;
    state.errorMessage = '';
  },
  [types.UPDATE_SETTINGS_SUCCESS](state, data) {
    state.settings = { ...mapDataToState(data) };
    state.isLoading = false;
    state.isUpdated = true;
  },
  [types.UPDATE_SETTINGS_ERROR](state) {
    state.isLoading = false;
    state.errorMessage = APPROVAL_SETTINGS_I18N.savingErrorMessage;
  },
  [types.DISMISS_SUCCESS_MESSAGE](state) {
    state.isUpdated = false;
  },
  [types.DISMISS_ERROR_MESSAGE](state) {
    state.errorMessage = '';
  },
  [types.SET_PREVENT_AUTHOR_APPROVAL](state, preventAuthorApproval) {
    state.settings.preventAuthorApproval = preventAuthorApproval;
  },
  [types.SET_PREVENT_COMMITTERS_APPROVAL](state, preventCommittersApproval) {
    state.settings.preventCommittersApproval = preventCommittersApproval;
  },
  [types.SET_PREVENT_MR_APPROVAL_RULE_EDIT](state, preventMrApprovalRuleEdit) {
    state.settings.preventMrApprovalRuleEdit = preventMrApprovalRuleEdit;
  },
  [types.SET_REMOVE_APPROVALS_ON_PUSH](state, removeApprovalsOnPush) {
    state.settings.removeApprovalsOnPush = removeApprovalsOnPush;
  },
  [types.SET_REQUIRE_USER_PASSWORD](state, requireUserPassword) {
    state.settings.requireUserPassword = requireUserPassword;
  },
};
