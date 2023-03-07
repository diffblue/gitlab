import { memoize, uniqBy, uniqueId, flatten } from 'lodash';
import Api from '~/api';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { RULE_TYPE_ANY_APPROVER } from '../../../constants';
import { mapMRApprovalSettingsResponse } from '../../../mappers';
import * as types from './mutation_types';

const fetchGroupMembers = memoize((id) => Api.groupMembers(id).then((response) => response.data));

const fetchApprovers = ({ userRecords, groups }) => {
  const groupUsersAsync = Promise.all(groups.map(fetchGroupMembers));

  return groupUsersAsync
    .then(flatten)
    .then((groupUsers) => groupUsers.concat(userRecords))
    .then((users) => uniqBy(users, (x) => x.id));
};

const seedApprovers = (rule) =>
  rule.groups || rule.userRecords
    ? fetchApprovers(rule).then((approvers) => ({
        ...rule,
        approvers,
      }))
    : Promise.resolve(rule);

const seedUsers = ({ userRecords, ...rule }) =>
  userRecords ? { ...rule, users: userRecords } : rule;

const seedGroups = ({ groupRecords, ...rule }) =>
  groupRecords ? { ...rule, groups: groupRecords } : rule;

const seedLocalRule = (rule) => seedApprovers(rule).then(seedUsers).then(seedGroups);

const seedNewRule = (rule) => {
  const name = rule.ruleType === RULE_TYPE_ANY_APPROVER ? '' : rule.name;

  return {
    ...rule,
    isNew: true,
    name,
    id: uniqueId('new'),
  };
};

export const requestRules = ({ commit }) => {
  commit(types.SET_LOADING, true);
};

export const receiveRulesSuccess = ({ commit }, { resetToDefault, settings }) => {
  commit(types.SET_LOADING, false);
  commit(types.SET_RESET_TO_DEFAULT, resetToDefault);
  commit(types.SET_APPROVAL_SETTINGS, settings);
};

export const receiveRulesError = () => {
  createAlert({
    message: __('An error occurred fetching the approval rules.'),
  });
};

export const fetchRules = (
  { rootState, dispatch },
  { targetBranch = '', resetToDefault = false },
) => {
  dispatch('requestRules');

  const { mrSettingsPath, projectSettingsPath } = rootState.settings;
  const path = resetToDefault ? projectSettingsPath : mrSettingsPath || projectSettingsPath;

  const params = targetBranch
    ? {
        params: {
          target_branch: targetBranch,
        },
      }
    : null;

  return axios
    .get(path, params)
    .then((response) => mapMRApprovalSettingsResponse(response.data))
    .then((settings) => ({
      ...settings,
      rules: settings.rules.map((x) => (x.id ? x : seedNewRule(x))),
    }))
    .then((settings) => dispatch('receiveRulesSuccess', { settings, resetToDefault }))
    .catch(() => dispatch('receiveRulesError'));
};

export const postRule = ({ commit, dispatch }, rule) =>
  seedLocalRule(rule)
    .then(seedNewRule)
    .then((newRule) => {
      commit(types.POST_RULE, newRule);
      dispatch('createModal/close');
    })
    .catch((e) => {
      createAlert({
        message: __('An error occurred fetching the approvers for the new rule.'),
      });
      throw e;
    });

export const putRule = ({ commit, dispatch }, rule) =>
  seedLocalRule(rule)
    .then((newRule) => {
      commit(types.PUT_RULE, newRule);
      dispatch('createModal/close');
    })
    .catch((e) => {
      createAlert({
        message: __('An error occurred fetching the approvers for the new rule.'),
      });
      throw e;
    });

export const deleteRule = ({ commit, dispatch }, id) => {
  commit(types.DELETE_RULE, id);
  dispatch('deleteModal/close');
};

export const putFallbackRule = ({ commit, dispatch }, fallback) => {
  commit(types.SET_FALLBACK_RULE, fallback);
  dispatch('createModal/close');
};

export const requestEditRule = ({ dispatch }, rule) => {
  dispatch('createModal/open', rule);
};

export const requestDeleteRule = ({ dispatch }, rule) => {
  dispatch('deleteRule', rule.id);
};

export const postRegularRule = ({ commit, dispatch }, rule) =>
  seedLocalRule(rule)
    .then(seedNewRule)
    .then((newRule) => {
      commit(types.POST_REGULAR_RULE, newRule);
      commit(types.DELETE_ANY_RULE);
      dispatch('createModal/close');
    })
    .catch((e) => {
      createAlert({
        message: __('An error occurred fetching the approvers for the new rule.'),
      });
      throw e;
    });

export const setEmptyRule = ({ commit }) => {
  commit(types.SET_EMPTY_RULE);
};

export const addEmptyRule = ({ commit }) => {
  commit(types.ADD_EMPTY_RULE);
};

export const setTargetBranch = ({ commit }, targetBranch) =>
  commit(types.SET_TARGET_BRANCH, targetBranch);

export const undoRulesChange = ({ commit }) => commit(types.UNDO_RULES);
