import {
  groupIds,
  userIds,
  groupApprovers,
  decomposeApprovers,
  approversOutOfSync,
  approversOutOfSyncV2,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/actions';
import { GROUP_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';

// As returned by endpoints based on API::Entities::UserBasic
const userApprover = {
  avatar_url: null,
  id: 1,
  name: null,
  state: null,
  username: 'user name',
  web_url: null,
};

// As returned by endpoints based on API::Entities::PublicGroupDetails
const groupApprover = {
  avatar_url: null,
  id: 2,
  name: null,
  full_name: null,
  full_path: 'full path',
  web_url: null,
};

const actionDataWithoutApprovers = {
  approvals_required: 1,
  type: 'require_approval',
};

const unknownApprover = { id: 3, name: null };

const allApprovers = [userApprover, groupApprover];

const groupedApprovers = groupApprovers(allApprovers);

const userOnlyGroupedApprovers = groupApprovers([userApprover]);

describe('groupApprovers', () => {
  describe('with mixed approvers', () => {
    it('returns a copy of the input values with their proper type attribute', () => {
      expect(groupApprovers(allApprovers)).toStrictEqual([
        { ...userApprover, type: 'user', value: 'gid://gitlab/User/1' },
        { ...groupApprover, type: 'group' },
      ]);
    });

    it('sets types depending on whether the approver is a group or a user', () => {
      const approvers = groupApprovers(allApprovers);
      expect(approvers.find((approver) => approver.id === userApprover.id)).toEqual(
        expect.objectContaining({ type: 'user' }),
      );
      expect(approvers.find((approver) => approver.id === groupApprover.id)).toEqual(
        expect.objectContaining({ type: 'group' }),
      );
    });
  });

  it('sets group as a type for group related approvers', () => {
    expect(groupApprovers([groupApprover])).toStrictEqual([{ ...groupApprover, type: 'group' }]);
  });

  it('sets user as a type for user related approvers', () => {
    expect(groupApprovers([userApprover])).toStrictEqual([
      { ...userApprover, type: 'user', value: 'gid://gitlab/User/1' },
    ]);
  });

  it('does not set a type if neither group or user keys are present', () => {
    expect(groupApprovers([unknownApprover])).toStrictEqual([
      { id: unknownApprover.id, name: null },
    ]);
  });
});

describe('decomposeApprovers', () => {
  it('returns a copy of approvers adding id fields for both group and users', () => {
    expect(decomposeApprovers(actionDataWithoutApprovers, groupedApprovers)).toStrictEqual({
      ...actionDataWithoutApprovers,
      group_approvers_ids: [groupApprover.id],
      user_approvers_ids: [userApprover.id],
    });
  });

  it('removes group_approvers and user_approvers keys only keeping the id fields', () => {
    expect(
      decomposeApprovers(
        { ...actionDataWithoutApprovers, user_approvers: null, group_approvers: null },
        groupedApprovers,
      ),
    ).toStrictEqual({
      ...actionDataWithoutApprovers,
      group_approvers_ids: [groupApprover.id],
      user_approvers_ids: [userApprover.id],
    });
  });

  it('returns only user info when group info is empty', () => {
    expect(
      decomposeApprovers({ ...actionDataWithoutApprovers }, userOnlyGroupedApprovers),
    ).toStrictEqual({
      ...actionDataWithoutApprovers,
      user_approvers_ids: [userApprover.id],
    });
  });

  it('removes unrelated keys', () => {
    expect(
      decomposeApprovers({ ...actionDataWithoutApprovers, existingKey: null }, groupedApprovers),
    ).toStrictEqual({
      ...actionDataWithoutApprovers,
      group_approvers_ids: [groupApprover.id],
      user_approvers_ids: [userApprover.id],
    });
  });

  it('does not returns any approvers for unknown types', () => {
    expect(decomposeApprovers(actionDataWithoutApprovers, [unknownApprover])).toStrictEqual(
      actionDataWithoutApprovers,
    );
  });
});

describe('userIds', () => {
  it('returns only approver with type set to user', () => {
    expect(userIds(groupedApprovers)).toStrictEqual([userApprover.id]);
  });
});

describe('groupIds', () => {
  it('returns only approver with type set to group', () => {
    expect(groupIds(groupedApprovers)).toStrictEqual([groupApprover.id]);
  });
});

describe('approversOutOfSync', () => {
  describe('with user_approvers_ids only', () => {
    it.each`
      ids       | approvers         | result
      ${[1]}    | ${[userApprover]} | ${false}
      ${[]}     | ${[]}             | ${false}
      ${[]}     | ${[userApprover]} | ${true}
      ${[1]}    | ${[]}             | ${true}
      ${[1, 2]} | ${[userApprover]} | ${true}
      ${[2]}    | ${[]}             | ${true}
      ${[2]}    | ${[userApprover]} | ${true}
    `(
      'return $result when ids and approvers length equal to $ids and $approvers.length',
      ({ ids, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers_ids: ids,
        };
        expect(approversOutOfSync(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers only', () => {
    it.each`
      usernames                       | approvers         | result
      ${['user name']}                | ${[userApprover]} | ${false}
      ${[]}                           | ${[]}             | ${false}
      ${[]}                           | ${[userApprover]} | ${true}
      ${['user name']}                | ${[]}             | ${true}
      ${['user name', 'not present']} | ${[userApprover]} | ${true}
      ${['not present']}              | ${[]}             | ${true}
      ${['not present']}              | ${[userApprover]} | ${true}
    `(
      'return $result when usernames and approvers length equal to $usernames and $approvers.length',
      ({ usernames, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
        };
        expect(approversOutOfSync(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers and user_approvers_ids', () => {
    it.each`
      ids    | usernames          | approvers         | result
      ${[]}  | ${['user name']}   | ${[userApprover]} | ${false}
      ${[1]} | ${[]}              | ${[userApprover]} | ${false}
      ${[]}  | ${[]}              | ${[]}             | ${false}
      ${[1]} | ${['user name']}   | ${[userApprover]} | ${true}
      ${[1]} | ${['not present']} | ${[userApprover]} | ${true}
      ${[2]} | ${['user name']}   | ${[userApprover]} | ${true}
    `(
      'return $result when ids, usernames and approvers length equal to $ids, $usernames and $approvers.length',
      ({ ids, usernames, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
          user_approvers_ids: ids,
        };
        expect(approversOutOfSync(action, approvers)).toBe(result);
      },
    );
  });
  describe('with group_approvers_ids only', () => {
    it.each`
      ids       | approvers          | result
      ${[2]}    | ${[groupApprover]} | ${false}
      ${[]}     | ${[]}              | ${false}
      ${[]}     | ${[groupApprover]} | ${true}
      ${[2]}    | ${[]}              | ${true}
      ${[2, 3]} | ${[groupApprover]} | ${true}
      ${[3]}    | ${[]}              | ${true}
      ${[3]}    | ${[groupApprover]} | ${true}
    `(
      'return $result when ids and approvers length equal to $ids and $approvers.length',
      ({ ids, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          group_approvers_ids: ids,
        };
        expect(approversOutOfSync(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers, user_approvers_ids and group_approvers_ids', () => {
    it.each`
      userApproversIds | usernames        | groupApproversIds | approvers          | result
      ${[]}            | ${['user name']} | ${[2]}            | ${allApprovers}    | ${false}
      ${[1]}           | ${[]}            | ${[2]}            | ${allApprovers}    | ${false}
      ${[]}            | ${[]}            | ${[]}             | ${[]}              | ${false}
      ${[1]}           | ${['user name']} | ${[2]}            | ${allApprovers}    | ${true}
      ${[]}            | ${['user name']} | ${[3]}            | ${allApprovers}    | ${true}
      ${[1]}           | ${[]}            | ${[3]}            | ${allApprovers}    | ${true}
      ${[]}            | ${[]}            | ${[2]}            | ${[groupApprover]} | ${false}
      ${[1]}           | ${[]}            | ${[2]}            | ${[groupApprover]} | ${true}
      ${[]}            | ${['user name']} | ${[2]}            | ${[groupApprover]} | ${true}
      ${[]}            | ${['user name']} | ${[]}             | ${[userApprover]}  | ${false}
      ${[1]}           | ${[]}            | ${[]}             | ${[userApprover]}  | ${false}
      ${[1]}           | ${[]}            | ${[2]}            | ${[userApprover]}  | ${true}
    `(
      'return $result when user_ids, usernames, group_ids and approvers length equal to $userApproversIds, $usernames, $groupApproversIds and $approvers.length',
      ({ userApproversIds, usernames, groupApproversIds, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
          user_approvers_ids: userApproversIds,
          group_approvers_ids: groupApproversIds,
        };
        expect(approversOutOfSync(action, approvers)).toBe(result);
      },
    );
  });
  describe('with group_approvers only', () => {
    it.each`
      fullPath                        | approvers          | result
      ${['full path']}                | ${[groupApprover]} | ${false}
      ${[]}                           | ${[]}              | ${false}
      ${[]}                           | ${[groupApprover]} | ${true}
      ${['full path']}                | ${[]}              | ${true}
      ${['full path', 'not present']} | ${[groupApprover]} | ${true}
      ${['not present']}              | ${[]}              | ${true}
      ${['not present']}              | ${[groupApprover]} | ${true}
    `(
      'return $result when full_path and approvers length equal to $full_path and $approvers.length',
      ({ fullPath, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          group_approvers: fullPath,
        };
        expect(approversOutOfSync(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers, user_approvers_ids, group_approvers_ids and group_approvers', () => {
    it.each`
      userApproversIds | usernames        | groupApproversIds | groupPaths         | approvers           | result
      ${[]}            | ${['user name']} | ${[2]}            | ${[]}              | ${allApprovers}     | ${false}
      ${[1]}           | ${[]}            | ${[2]}            | ${[]}              | ${allApprovers}     | ${false}
      ${[1]}           | ${[]}            | ${[]}             | ${['full path']}   | ${allApprovers}     | ${false}
      ${[]}            | ${['user name']} | ${[]}             | ${['full path']}   | ${allApprovers}     | ${false}
      ${[]}            | ${[]}            | ${[]}             | ${[]}              | ${[]}               | ${false}
      ${[]}            | ${['user name']} | ${[3]}            | ${[]}              | ${allApprovers}     | ${true}
      ${[1]}           | ${[]}            | ${[3]}            | ${[]}              | ${allApprovers}     | ${true}
      ${[1]}           | ${[]}            | ${[]}             | ${['not present']} | ${allApprovers}     | ${true}
      ${[]}            | ${['user name']} | ${[]}             | ${['not present']} | ${allApprovers}     | ${true}
      ${[1]}           | ${[]}            | ${[]}             | ${['full path']}   | ${[groupApprovers]} | ${true}
      ${[]}            | ${['user name']} | ${[]}             | ${['full path']}   | ${[groupApprovers]} | ${true}
    `(
      'return $result when user_ids, usernames, group_ids, group_paths and approvers length equal to $userApproversIds, $usernames, $groupApproversIds, $groupPaths and $approvers.length',
      ({ userApproversIds, usernames, groupApproversIds, groupPaths, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
          user_approvers_ids: userApproversIds,
          group_approvers_ids: groupApproversIds,
          group_approvers: groupPaths,
        };
        expect(approversOutOfSync(action, approvers)).toBe(result);
      },
    );
  });
});

describe('approversOutOfSyncV2', () => {
  const userApproverV2 = {
    avatar_url: null,
    id: 1,
    name: null,
    state: null,
    type: USER_TYPE,
    username: 'user name',
    web_url: null,
  };

  const groupApproverV2 = {
    avatar_url: null,
    id: 2,
    name: null,
    full_name: null,
    full_path: 'path/to/group',
    type: GROUP_TYPE,
    web_url: null,
  };

  const noExistingApprovers = {};
  const existingUserApprover = { user: [userApproverV2] };
  const existingGroupApprover = { group: [groupApproverV2] };
  const existingMixedApprovers = { ...existingUserApprover, ...existingGroupApprover };

  describe('with user_approvers_ids only', () => {
    it.each`
      ids                       | approvers               | result
      ${[userApproverV2.id]}    | ${existingUserApprover} | ${false}
      ${[]}                     | ${noExistingApprovers}  | ${false}
      ${[]}                     | ${existingUserApprover} | ${true}
      ${[userApproverV2.id]}    | ${noExistingApprovers}  | ${true}
      ${[userApproverV2.id, 3]} | ${existingUserApprover} | ${true}
      ${[3]}                    | ${noExistingApprovers}  | ${true}
      ${[3]}                    | ${existingUserApprover} | ${true}
    `(
      'return $result when ids and approvers length equal to $ids and $approvers.length',
      ({ ids, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers_ids: ids,
        };
        expect(approversOutOfSyncV2(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers only', () => {
    it.each`
      usernames                                   | approvers               | result
      ${[userApproverV2.username]}                | ${existingUserApprover} | ${false}
      ${[]}                                       | ${noExistingApprovers}  | ${false}
      ${[]}                                       | ${existingUserApprover} | ${true}
      ${[userApproverV2.username]}                | ${noExistingApprovers}  | ${true}
      ${[userApproverV2.username, 'not present']} | ${existingUserApprover} | ${true}
      ${['not present']}                          | ${noExistingApprovers}  | ${true}
      ${['not present']}                          | ${existingUserApprover} | ${true}
    `(
      'return $result when usernames and approvers length equal to $usernames and $approvers.length',
      ({ usernames, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
        };
        expect(approversOutOfSyncV2(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers and user_approvers_ids', () => {
    it.each`
      ids                    | usernames                    | approvers               | result
      ${[]}                  | ${[userApproverV2.username]} | ${existingUserApprover} | ${false}
      ${[userApproverV2.id]} | ${[]}                        | ${existingUserApprover} | ${false}
      ${[]}                  | ${[]}                        | ${noExistingApprovers}  | ${false}
      ${[userApproverV2.id]} | ${[userApproverV2.username]} | ${existingUserApprover} | ${true}
      ${[userApproverV2.id]} | ${['not present']}           | ${existingUserApprover} | ${true}
      ${[3]}                 | ${[userApproverV2.username]} | ${existingUserApprover} | ${true}
    `(
      'return $result when ids, usernames and approvers length equal to $ids, $usernames and $approvers.length',
      ({ ids, usernames, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
          user_approvers_ids: ids,
        };
        expect(approversOutOfSyncV2(action, approvers)).toBe(result);
      },
    );
  });
  describe('with group_approvers_ids only', () => {
    it.each`
      ids                        | approvers                | result
      ${[groupApproverV2.id]}    | ${existingGroupApprover} | ${false}
      ${[]}                      | ${noExistingApprovers}   | ${false}
      ${[]}                      | ${existingGroupApprover} | ${true}
      ${[groupApproverV2.id]}    | ${noExistingApprovers}   | ${true}
      ${[groupApproverV2.id, 3]} | ${existingGroupApprover} | ${true}
      ${[3]}                     | ${noExistingApprovers}   | ${true}
      ${[3]}                     | ${existingGroupApprover} | ${true}
    `(
      'return $result when ids and approvers length equal to $ids and $approvers.length',
      ({ ids, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          group_approvers_ids: ids,
        };
        expect(approversOutOfSyncV2(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers, user_approvers_ids and group_approvers_ids', () => {
    it.each`
      userApproversIds       | usernames                    | groupApproversIds       | approvers                 | result
      ${[]}                  | ${[userApproverV2.username]} | ${[groupApproverV2.id]} | ${existingMixedApprovers} | ${false}
      ${[userApproverV2.id]} | ${[]}                        | ${[groupApproverV2.id]} | ${existingMixedApprovers} | ${false}
      ${[]}                  | ${[]}                        | ${[]}                   | ${noExistingApprovers}    | ${false}
      ${[userApproverV2.id]} | ${[userApproverV2.username]} | ${[groupApproverV2.id]} | ${existingMixedApprovers} | ${true}
      ${[]}                  | ${[userApproverV2.username]} | ${[3]}                  | ${existingMixedApprovers} | ${true}
      ${[userApproverV2.id]} | ${[]}                        | ${[3]}                  | ${existingMixedApprovers} | ${true}
      ${[]}                  | ${[]}                        | ${[groupApproverV2.id]} | ${existingGroupApprover}  | ${false}
      ${[userApproverV2.id]} | ${[]}                        | ${[groupApproverV2.id]} | ${existingGroupApprover}  | ${true}
      ${[]}                  | ${[userApproverV2.username]} | ${[groupApproverV2.id]} | ${existingGroupApprover}  | ${true}
      ${[]}                  | ${[userApproverV2.username]} | ${[]}                   | ${existingUserApprover}   | ${false}
      ${[userApproverV2.id]} | ${[]}                        | ${[]}                   | ${existingUserApprover}   | ${false}
      ${[userApproverV2.id]} | ${[]}                        | ${[groupApproverV2.id]} | ${existingUserApprover}   | ${true}
    `(
      'return $result when user_ids, usernames, group_ids and approvers length equal to $userApproversIds, $usernames, $groupApproversIds and $approvers.length',
      ({ userApproversIds, usernames, groupApproversIds, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
          user_approvers_ids: userApproversIds,
          group_approvers_ids: groupApproversIds,
        };
        expect(approversOutOfSyncV2(action, approvers)).toBe(result);
      },
    );
  });
  describe('with group_approvers only', () => {
    it.each`
      fullPath                                      | approvers                | result
      ${[groupApproverV2.full_path]}                | ${existingGroupApprover} | ${false}
      ${[]}                                         | ${noExistingApprovers}   | ${false}
      ${[]}                                         | ${existingGroupApprover} | ${true}
      ${[groupApproverV2.full_path]}                | ${noExistingApprovers}   | ${true}
      ${[groupApproverV2.full_path, 'not present']} | ${existingGroupApprover} | ${true}
      ${['not present']}                            | ${noExistingApprovers}   | ${true}
      ${['not present']}                            | ${existingGroupApprover} | ${true}
    `(
      'return $result when full_path and approvers length equal to $full_path and $approvers.length',
      ({ fullPath, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          group_approvers: fullPath,
        };
        expect(approversOutOfSyncV2(action, approvers)).toBe(result);
      },
    );
  });
  describe('with user_approvers, user_approvers_ids, group_approvers_ids and group_approvers', () => {
    it.each`
      userApproversIds       | usernames                    | groupApproversIds       | groupPaths                     | approvers                 | result
      ${[]}                  | ${[userApproverV2.username]} | ${[groupApproverV2.id]} | ${[]}                          | ${existingMixedApprovers} | ${false}
      ${[userApproverV2.id]} | ${[]}                        | ${[groupApproverV2.id]} | ${[]}                          | ${existingMixedApprovers} | ${false}
      ${[userApproverV2.id]} | ${[]}                        | ${[]}                   | ${[groupApproverV2.full_path]} | ${existingMixedApprovers} | ${false}
      ${[]}                  | ${[userApproverV2.username]} | ${[]}                   | ${[groupApproverV2.full_path]} | ${existingMixedApprovers} | ${false}
      ${[]}                  | ${[]}                        | ${[]}                   | ${[]}                          | ${noExistingApprovers}    | ${false}
      ${[]}                  | ${[userApproverV2.username]} | ${[3]}                  | ${[]}                          | ${existingMixedApprovers} | ${true}
      ${[userApproverV2.id]} | ${[]}                        | ${[3]}                  | ${[]}                          | ${existingMixedApprovers} | ${true}
      ${[userApproverV2.id]} | ${[]}                        | ${[]}                   | ${['not present']}             | ${existingMixedApprovers} | ${true}
      ${[]}                  | ${[userApproverV2.username]} | ${[]}                   | ${['not present']}             | ${existingMixedApprovers} | ${true}
      ${[userApproverV2.id]} | ${[]}                        | ${[]}                   | ${[groupApproverV2.full_path]} | ${existingGroupApprover}  | ${true}
      ${[]}                  | ${[userApproverV2.username]} | ${[]}                   | ${[groupApproverV2.full_path]} | ${existingGroupApprover}  | ${true}
    `(
      'return $result when user_ids, usernames, group_ids, group_paths and approvers length equal to $userApproversIds, $usernames, $groupApproversIds, $groupPaths and $approvers.length',
      ({ userApproversIds, usernames, groupApproversIds, groupPaths, approvers, result }) => {
        const action = {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers: usernames,
          user_approvers_ids: userApproversIds,
          group_approvers_ids: groupApproversIds,
          group_approvers: groupPaths,
        };
        expect(approversOutOfSyncV2(action, approvers)).toBe(result);
      },
    );
  });
});
