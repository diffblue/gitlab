import {
  mapApprovalRuleRequest,
  mapApprovalSettingsResponse,
  mapApprovalFallbackRuleRequest,
} from 'ee/approvals/mappers';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import * as types from '../base/mutation_types';

export const receiveRulesSuccess = ({ commit }, approvalSettings) => {
  commit(types.SET_APPROVAL_SETTINGS, approvalSettings);
  commit(types.SET_LOADING, false);
};

export const fetchRules = ({ rootState, dispatch, commit }) => {
  const { settingsPath } = rootState.settings;

  commit(types.SET_LOADING, true);

  return axios
    .get(settingsPath)
    .then((response) =>
      dispatch('receiveRulesSuccess', mapApprovalSettingsResponse(response.data.rules)),
    )
    .catch(() =>
      createAlert({
        message: __('An error occurred fetching the approval rules.'),
      }),
    );
};

export const postRule = ({ rootState, dispatch }, rule) => {
  const { rulesPath } = rootState.settings;

  return axios
    .post(rulesPath, mapApprovalRuleRequest(rule))
    .then(() => dispatch('fetchRules'))
    .catch(() =>
      createAlert({
        message: __('An error occurred while adding approvers'),
      }),
    );
};

export const putRule = ({ rootState, dispatch }, { id, ...newRule }) => {
  const { rulesPath } = rootState.settings;

  return axios
    .put(`${rulesPath}/${id}`, mapApprovalRuleRequest(newRule))
    .then(() => dispatch('fetchRules'))
    .catch(() =>
      createAlert({
        message: __('An error occurred while updating approvers'),
      }),
    );
};

export const deleteRule = ({ rootState, dispatch }, id) => {
  const { rulesPath } = rootState.settings;

  return axios
    .delete(`${rulesPath}/${id}`)
    .then(() => dispatch('fetchRules'))
    .catch(() =>
      createAlert({
        message: __('An error occurred while deleting the approvers group'),
      }),
    );
};

export const putFallbackRule = ({ rootState, dispatch }, fallback) => {
  const { projectPath } = rootState.settings;

  return axios
    .put(projectPath, mapApprovalFallbackRuleRequest(fallback))
    .then(() => dispatch('fetchRules'))
    .catch(() =>
      createAlert({
        message: __('An error occurred while deleting the approvers group'),
      }),
    );
};
