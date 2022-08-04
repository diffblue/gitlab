import { cloneDeep } from 'lodash';
import { APPROVAL_SETTINGS_I18N } from '../../../constants';
import * as types from './mutation_types';

export default (mapDataToState) => ({
  [types.REQUEST_SETTINGS](state) {
    state.isLoading = true;
    state.errorMessage = '';
  },
  [types.RECEIVE_SETTINGS_SUCCESS](state, data) {
    state.settings = mapDataToState(data);
    state.initialSettings = cloneDeep(state.settings);
    state.isLoading = false;
  },
  [types.RECEIVE_SETTINGS_ERROR](state) {
    state.isLoading = false;
    state.errorMessage = APPROVAL_SETTINGS_I18N.loadingErrorMessage;
  },
  [types.REQUEST_UPDATE_SETTINGS](state) {
    state.isLoading = true;
    state.errorMessage = '';
  },
  [types.UPDATE_SETTINGS_SUCCESS](state, data) {
    state.settings = mapDataToState(data);
    state.initialSettings = cloneDeep(state.settings);
    state.isLoading = false;
  },
  [types.UPDATE_SETTINGS_ERROR](state) {
    state.isLoading = false;
    state.errorMessage = APPROVAL_SETTINGS_I18N.savingErrorMessage;
  },
  [types.DISMISS_ERROR_MESSAGE](state) {
    state.errorMessage = '';
  },
  [types.SET_PREVENT_AUTHOR_APPROVAL](state, value) {
    state.settings.preventAuthorApproval.value = value;
  },
  [types.SET_PREVENT_COMMITTERS_APPROVAL](state, value) {
    state.settings.preventCommittersApproval.value = value;
  },
  [types.SET_PREVENT_MR_APPROVAL_RULE_EDIT](state, value) {
    state.settings.preventMrApprovalRuleEdit.value = value;
  },
  [types.SET_REMOVE_APPROVALS_ON_PUSH](state, value) {
    state.settings.removeApprovalsOnPush.value = value;
  },
  [types.SET_SELECTIVE_CODE_OWNER_REMOVALS](state, value) {
    state.settings.selectiveCodeOwnerRemovals.value = value;
  },
  [types.SET_REQUIRE_USER_PASSWORD](state, value) {
    state.settings.requireUserPassword.value = value;
  },
});
