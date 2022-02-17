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
  const newAction = { ...action };
  delete newAction.group_approvers;
  delete newAction.user_approvers;
  return {
    ...newAction,
    user_approvers_ids: userIds(approvers),
    group_approvers_ids: groupIds(approvers),
  };
}
