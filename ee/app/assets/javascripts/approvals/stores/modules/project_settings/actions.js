import {
  mapApprovalRuleRequest,
  mapApprovalSettingsResponse,
  mapApprovalFallbackRuleRequest,
} from 'ee/approvals/mappers';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import * as types from '../base/mutation_types';

export const requestRules = ({ commit }) => {
  commit(types.SET_LOADING, true);
};

export const receiveRulesSuccess = ({ commit }, approvalSettings) => {
  commit(types.SET_APPROVAL_SETTINGS, approvalSettings);
  commit(types.SET_LOADING, false);
};

export const receiveRulesError = () => {
  createAlert({
    message: __('An error occurred fetching the approval rules.'),
  });
};

export const fetchRules = ({ rootState, dispatch }) => {
  dispatch('requestRules');

  const { rulesPath } = rootState.settings;

  return axios
    .get(rulesPath)
    .then((response) => dispatch('receiveRulesSuccess', mapApprovalSettingsResponse(response.data)))
    .catch(() => dispatch('receiveRulesError'));
};

export const postRuleSuccess = ({ dispatch }) => {
  dispatch('createModal/close');
  dispatch('fetchRules');
};

export const postRule = ({ rootState, dispatch }, rule) => {
  const { rulesPath } = rootState.settings;

  return axios
    .post(rulesPath, mapApprovalRuleRequest(rule))
    .then(() => dispatch('postRuleSuccess'));
};

export const putRule = ({ rootState, dispatch }, { id, ...newRule }) => {
  const { rulesPath } = rootState.settings;

  return axios
    .put(`${rulesPath}/${id}`, mapApprovalRuleRequest(newRule))
    .then(() => dispatch('postRuleSuccess'));
};

export const deleteRuleSuccess = ({ dispatch }) => {
  dispatch('deleteModal/close');
  dispatch('fetchRules');
};

export const deleteRuleError = () => {
  createAlert({
    message: __('An error occurred while deleting the approvers group'),
  });
};

export const deleteRule = ({ rootState, dispatch }, id) => {
  const { rulesPath } = rootState.settings;

  return axios
    .delete(`${rulesPath}/${id}`)
    .then(() => dispatch('deleteRuleSuccess'))
    .catch(() => dispatch('deleteRuleError'));
};

export const putFallbackRuleSuccess = ({ dispatch }) => {
  dispatch('createModal/close');
  dispatch('fetchRules');
};

export const putFallbackRule = ({ rootState, dispatch }, fallback) => {
  const { projectPath } = rootState.settings;

  return axios
    .put(projectPath, mapApprovalFallbackRuleRequest(fallback))
    .then(() => dispatch('putFallbackRuleSuccess'));
};

export const requestEditRule = ({ dispatch }, rule) => {
  dispatch('createModal/open', rule);
};

export const requestDeleteRule = ({ dispatch }, rule) => {
  dispatch('deleteModal/open', rule);
};

export const addEmptyRule = ({ commit }) => {
  commit(types.ADD_EMPTY_RULE);
};
