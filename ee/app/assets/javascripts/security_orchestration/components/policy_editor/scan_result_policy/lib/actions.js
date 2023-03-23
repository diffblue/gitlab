import { omitBy, isEmpty } from 'lodash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { n__, s__ } from '~/locale';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { GROUP_TYPE, ROLE_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';

export const APPROVER_TYPE_DICT = {
  [GROUP_TYPE]: ['group_approvers', 'group_approvers_ids'],
  [ROLE_TYPE]: ['role_approvers'],
  [USER_TYPE]: ['user_approvers', 'user_approvers_ids'],
};

export const ADD_APPROVER_LABEL = s__('SecurityOrchestration|Add new approver');

export const APPROVER_TYPE_LIST_ITEMS = [
  { text: s__('SecurityOrchestration|Roles'), value: ROLE_TYPE },
  { text: s__('SecurityOrchestration|Individual users'), value: USER_TYPE },
  { text: s__('SecurityOrchestration|Groups'), value: GROUP_TYPE },
];

/*
  Return the ids for all approvers of the group type.
*/
export function groupIds(approvers) {
  return approvers
    .filter((approver) => approver.type === GROUP_TYPE)
    .map((approver) => approver.id);
}

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
        value: convertToGraphQLId(TYPENAME_USER, approver.id),
      };
    }
    return approver;
  });
}

// TODO delete this function as part of the clean up for the `:scan_result_role_action` feature
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

export const removeAvailableApproverType = (array, type) =>
  array.filter(({ value }) => value !== type);

/*
  Convert approvers into yaml fields (user_approvers, users_approvers_ids) in relation to action.
*/
export const createActionFromApprovers = ({ type, approvals_required }, approvers) => {
  const newAction = { type, approvals_required };

  if (approvers[USER_TYPE]) {
    newAction.user_approvers_ids = userIds(approvers[USER_TYPE]);
  }

  if (approvers[GROUP_TYPE]) {
    newAction.group_approvers_ids = groupIds(approvers[GROUP_TYPE]);
  }

  if (approvers[ROLE_TYPE]) {
    newAction.role_approvers = approvers[ROLE_TYPE];
  }

  return newAction;
};

/*
  Check if users are present in approvers
*/
function usersOutOfSync(action, approvers) {
  // TODO delete this filter as part of the clean up for the `:scan_result_role_action` feature
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
  // TODO delete this filter as part of the clean up for the `:scan_result_role_action` feature
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
export function approversOutOfSyncV2(action, { user = [], group = [] }) {
  return usersOutOfSync(action, user) || groupsOutOfSync(action, group);
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
    '%{requireStart}Require%{requireEnd} %{approvalsRequired} %{approvalStart}approval%{approvalEnd} from:',
    '%{requireStart}Require%{requireEnd} %{approvalsRequired} %{approvalStart}approvals%{approvalEnd} from:',
    numOfApproversRequired,
  );
};

export const MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE = s__('SecurityOrchestration|or from:');

export const DEFAULT_APPROVER_DROPDOWN_TEXT = s__('SecurityOrchestration|Choose approver type');
