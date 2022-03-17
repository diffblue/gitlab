import { omitBy, isEmpty } from 'lodash';

export const USER_TYPE = 'user';
const GROUP_TYPE = 'group';

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

/*
  Group existing approvers into a single array.
*/
export function groupApprovers(existingApprovers) {
  const approvers = [...existingApprovers];
  const userUniqKeys = ['state', 'username'];
  const groupUniqKeys = ['full_name', 'full_path'];

  return approvers.map((approver) => {
    const approverKeys = Object.keys(approver);

    if (approverKeys.includes(...groupUniqKeys)) {
      return { ...approver, type: GROUP_TYPE };
    } else if (approverKeys.includes(...userUniqKeys)) {
      return { ...approver, type: USER_TYPE };
    }
    return approver;
  });
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
