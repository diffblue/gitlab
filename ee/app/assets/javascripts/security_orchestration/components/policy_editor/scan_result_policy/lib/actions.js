import { omitBy, isEmpty } from 'lodash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { n__, s__ } from '~/locale';
import { TYPE_GROUP, TYPE_USER } from '~/graphql_shared/constants';

export const GROUP_TYPE = 'group';
export const USER_TYPE = 'user';

export const APPROVER_TYPE_DICT = {
  [GROUP_TYPE]: ['group_approvers', 'group_approvers_ids'],
  [USER_TYPE]: ['user_approvers', 'user_approvers_ids'],
};

export const ADD_APPROVER_LABEL = s__('SecurityOrchestration|Add new approver');

export const APPROVER_TYPE_LIST_ITEMS = [
  { text: s__('SecurityOrchestration|Individual users'), value: USER_TYPE },
  { text: s__('SecurityOrchestration|Groups'), value: GROUP_TYPE },
];

// TODO delete this function as part of the clean up for the `:scan_result_role_action` feature
/*
  Return the ids for all approvers of the group type.
*/
export function groupIds(approvers) {
  return approvers
    .filter((approver) => approver.type === GROUP_TYPE)
    .map((approver) => approver.id);
}

// TODO delete this file as part of the clean up for the `:scan_result_role_action` feature
/*
  Return the ids for all approvers of the user type.
*/
export function userIds(approvers) {
  return approvers.filter((approver) => approver.type === USER_TYPE).map((approver) => approver.id);
}

// TODO delete this function as part of the clean up for the `:scan_result_role_action` feature
/*
  Group existing approvers into a single array.
*/
export function groupApprovers(existingApprovers) {
  const userUniqKeys = ['state', 'username'];
  const groupUniqKeys = ['full_name', 'full_path'];

  return existingApprovers.map((approver) => {
    const approverKeys = Object.keys(approver);

    if (approverKeys.includes(...groupUniqKeys)) {
      return { ...approver, type: GROUP_TYPE };
    } else if (approverKeys.includes(...userUniqKeys)) {
      return {
        ...approver,
        type: USER_TYPE,
        value: convertToGraphQLId(TYPE_USER, approver.id),
      };
    }
    return approver;
  });
}

/**
 * Separate existing approvers by type
 * @param {Array} existingApprovers all approvers
 * @returns {Object} approvers separated by type
 */
export function groupApproversV2(existingApprovers) {
  const USER_TYPE_UNIQ_KEY = 'username';
  // TODO remove groupUniqKeys with the removal of the `:scan_result_role_action` feature flag (https://gitlab.com/gitlab-org/gitlab/-/issues/377866)
  const GROUP_TYPE_UNIQ_KEY = 'full_name';
  const GROUP_TYPE_UNIQ_KEY_V2 = 'fullName';

  return existingApprovers.reduce(
    (acc, approver) => {
      const approverKeys = Object.keys(approver);

      if (
        approverKeys.includes(GROUP_TYPE_UNIQ_KEY) ||
        approverKeys.includes(GROUP_TYPE_UNIQ_KEY_V2)
      ) {
        acc.groups.push({
          ...approver,
          type: GROUP_TYPE,
          value: convertToGraphQLId(TYPE_GROUP, approver.id),
        });
      } else if (approverKeys.includes(USER_TYPE_UNIQ_KEY)) {
        acc.users.push({
          ...approver,
          type: USER_TYPE,
          value: convertToGraphQLId(TYPE_USER, approver.id),
        });
      }

      return acc;
    },
    { users: [], groups: [] },
  );
}

/*
  Convert approvers into yaml fields (user_approvers, users_approvers_ids) in relation to action.
*/
export function decomposeApprovers(action, approvers) {
  const newAction = { type: action.type, approvals_required: action.approvals_required };
  const approversInfo = omitBy(
    {
      user_approvers_ids: userIds(approvers),
      group_approvers_ids: groupIds(approvers),
    },
    isEmpty,
  );
  return { ...newAction, ...approversInfo };
}

/*
  Check if users are present in approvers
*/
function usersOutOfSync(action, approvers) {
  const users = approvers.filter((approver) => approver.type === USER_TYPE);
  const usersIDs =
    action?.user_approvers_ids?.some((id) => !users.find((approver) => approver.id === id)) ||
    false;
  const usersNames =
    action?.user_approvers?.some(
      (userName) => !users.find((approver) => approver.username === userName),
    ) || false;
  const userLength =
    (action?.user_approvers?.length || 0) + (action?.user_approvers_ids?.length || 0);

  return usersIDs || usersNames || userLength !== users.length;
}

/*
  Check if groups are present in approvers
*/
function groupsOutOfSync(action, approvers) {
  const groups = approvers.filter((approver) => approver.type === GROUP_TYPE);
  const groupsIDs =
    action?.group_approvers_ids?.some((id) => !groups.find((approver) => approver.id === id)) ||
    false;
  const groupsPaths =
    action?.group_approvers?.some(
      (path) => !groups.find((approver) => approver.full_path === path),
    ) || false;
  const groupLength =
    (action?.group_approvers?.length || 0) + (action?.group_approvers_ids?.length || 0);

  return groupsIDs || groupsPaths || groupLength !== groups.length;
}

/*
  Check if yaml is out of sync with available approvers
*/
export function approversOutOfSync(action, existingApprovers) {
  const approvers = groupApprovers(existingApprovers);
  return usersOutOfSync(action, approvers) || groupsOutOfSync(action, approvers);
}

export const getDefaultHumanizedTemplate = (numOfApproversRequired) => {
  return n__(
    '%{requireStart}Require%{requireEnd} %{approvalsRequired} %{approvalStart}approval%{approvalEnd} from: %{approverType}%{approvers}',
    '%{requireStart}Require%{requireEnd} %{approvalsRequired} %{approvalStart}approvals%{approvalEnd} from: %{approverType}%{approvers}',
    numOfApproversRequired,
  );
};

export const MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE = s__(
  'SecurityOrchestration|or from: %{approverType}%{approvers}',
);

export const DEFAULT_APPROVER_DROPDOWN_TEXT = s__('SecurityOrchestration|Choose approver type');
