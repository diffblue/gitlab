import { getUser, getProjectMembers, getGroupMembers } from '~/rest_api';
import Api from 'ee/api';
import * as types from './mutation_types';

const INHERITED_GROUPS = '1';

const fetchUsersForRuleForProject = (
  projectId,
  {
    user_id: userId,
    group_id: groupId,
    group_inheritance_type: groupInheritanceType,
    access_level: accessLevel,
  },
) => {
  if (userId != null) {
    return getUser(userId).then(({ data }) => [data]);
  } else if (groupId != null) {
    return getGroupMembers(groupId, groupInheritanceType === INHERITED_GROUPS).then(
      ({ data }) => data,
    );
  }

  return getProjectMembers(projectId, groupInheritanceType === INHERITED_GROUPS).then(({ data }) =>
    data.filter(({ access_level: memberAccessLevel }) => memberAccessLevel >= accessLevel),
  );
};

export const fetchProtectedEnvironments = ({ state, commit, dispatch }) => {
  commit(types.REQUEST_PROTECTED_ENVIRONMENTS);

  return Api.protectedEnvironments(state.projectId)
    .then(({ data }) => {
      commit(types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS, data);
      dispatch('fetchAllMembers');
    })
    .catch((error) => {
      commit(types.RECEIVE_PROTECTED_ENVIRONMENTS_ERROR, error);
    });
};

export const fetchAllMembers = async ({ state, dispatch, commit }) => {
  commit(types.REQUEST_MEMBERS);

  try {
    await Promise.all(
      state.protectedEnvironments.flatMap((env) =>
        env.deploy_access_levels.map((rule) => dispatch('fetchMembers', rule)),
      ),
    );
  } finally {
    commit(types.RECEIVE_MEMBERS_FINISH);
  }
};

export const fetchMembers = ({ state, commit }, rule) => {
  return fetchUsersForRuleForProject(state.projectId, rule)
    .then((users) => {
      commit(types.RECEIVE_MEMBER_SUCCESS, { rule, users });
    })
    .catch((error) => {
      commit(types.RECEIVE_MEMBERS_ERROR, error);
    });
};

export const deleteRule = ({ dispatch }, { environment, rule }) => {
  const deletedRuleEntries = [
    ['_destroy', true],
    ...Object.entries(rule).filter(([, value]) => value),
  ];
  const updatedEnvironment = {
    name: environment.name,
    deploy_access_levels: [Object.fromEntries(deletedRuleEntries)],
  };

  dispatch('updateEnvironment', updatedEnvironment);
};

export const updateEnvironment = ({ state, commit }, environment) => {
  commit(types.REQUEST_UPDATE_PROTECTED_ENVIRONMENT);

  return Api.updateProtectedEnvironment(state.projectId, environment)
    .then(({ data }) => {
      commit(types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_SUCCESS, data);
    })
    .catch((error) => {
      commit(types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_ERROR, error);
    });
};
