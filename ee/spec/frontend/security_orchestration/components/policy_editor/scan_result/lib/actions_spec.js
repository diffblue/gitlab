import {
  APPROVER_TYPE_DICT,
  approversOutOfSync,
  actionHasType,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/actions';
import { GROUP_TYPE, USER_TYPE, ROLE_TYPE } from 'ee/security_orchestration/constants';

describe('approversOutOfSync', () => {
  const userApprover = {
    avatarUrl: null,
    id: 1,
    name: null,
    state: null,
    type: USER_TYPE,
    username: 'user name',
    webUrl: null,
  };

  const groupApprover = {
    avatarUrl: null,
    id: 2,
    name: null,
    fullName: null,
    fullPath: 'path/to/group',
    type: GROUP_TYPE,
    webUrl: null,
  };

  const noExistingApprovers = {};
  const existingUserApprover = { user: [userApprover] };
  const existingGroupApprover = { group: [groupApprover] };
  const existingMixedApprovers = { ...existingUserApprover, ...existingGroupApprover };

  describe('with user_approvers_ids only', () => {
    it.each`
      ids                     | approvers               | result
      ${[userApprover.id]}    | ${existingUserApprover} | ${false}
      ${[]}                   | ${noExistingApprovers}  | ${false}
      ${[]}                   | ${existingUserApprover} | ${true}
      ${[userApprover.id]}    | ${noExistingApprovers}  | ${true}
      ${[userApprover.id, 3]} | ${existingUserApprover} | ${true}
      ${[3]}                  | ${noExistingApprovers}  | ${true}
      ${[3]}                  | ${existingUserApprover} | ${true}
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
      usernames                                 | approvers               | result
      ${[userApprover.username]}                | ${existingUserApprover} | ${false}
      ${[]}                                     | ${noExistingApprovers}  | ${false}
      ${[]}                                     | ${existingUserApprover} | ${true}
      ${[userApprover.username]}                | ${noExistingApprovers}  | ${true}
      ${[userApprover.username, 'not present']} | ${existingUserApprover} | ${true}
      ${['not present']}                        | ${noExistingApprovers}  | ${true}
      ${['not present']}                        | ${existingUserApprover} | ${true}
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
      ids                  | usernames                  | approvers               | result
      ${[]}                | ${[userApprover.username]} | ${existingUserApprover} | ${false}
      ${[userApprover.id]} | ${[]}                      | ${existingUserApprover} | ${false}
      ${[]}                | ${[]}                      | ${noExistingApprovers}  | ${false}
      ${[userApprover.id]} | ${[userApprover.username]} | ${existingUserApprover} | ${true}
      ${[userApprover.id]} | ${['not present']}         | ${existingUserApprover} | ${true}
      ${[3]}               | ${[userApprover.username]} | ${existingUserApprover} | ${true}
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
      ids                      | approvers                | result
      ${[groupApprover.id]}    | ${existingGroupApprover} | ${false}
      ${[]}                    | ${noExistingApprovers}   | ${false}
      ${[]}                    | ${existingGroupApprover} | ${true}
      ${[groupApprover.id]}    | ${noExistingApprovers}   | ${true}
      ${[groupApprover.id, 3]} | ${existingGroupApprover} | ${true}
      ${[3]}                   | ${noExistingApprovers}   | ${true}
      ${[3]}                   | ${existingGroupApprover} | ${true}
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
      userApproversIds     | usernames                  | groupApproversIds     | approvers                 | result
      ${[]}                | ${[userApprover.username]} | ${[groupApprover.id]} | ${existingMixedApprovers} | ${false}
      ${[userApprover.id]} | ${[]}                      | ${[groupApprover.id]} | ${existingMixedApprovers} | ${false}
      ${[]}                | ${[]}                      | ${[]}                 | ${noExistingApprovers}    | ${false}
      ${[userApprover.id]} | ${[userApprover.username]} | ${[groupApprover.id]} | ${existingMixedApprovers} | ${true}
      ${[]}                | ${[userApprover.username]} | ${[3]}                | ${existingMixedApprovers} | ${true}
      ${[userApprover.id]} | ${[]}                      | ${[3]}                | ${existingMixedApprovers} | ${true}
      ${[]}                | ${[]}                      | ${[groupApprover.id]} | ${existingGroupApprover}  | ${false}
      ${[userApprover.id]} | ${[]}                      | ${[groupApprover.id]} | ${existingGroupApprover}  | ${true}
      ${[]}                | ${[userApprover.username]} | ${[groupApprover.id]} | ${existingGroupApprover}  | ${true}
      ${[]}                | ${[userApprover.username]} | ${[]}                 | ${existingUserApprover}   | ${false}
      ${[userApprover.id]} | ${[]}                      | ${[]}                 | ${existingUserApprover}   | ${false}
      ${[userApprover.id]} | ${[]}                      | ${[groupApprover.id]} | ${existingUserApprover}   | ${true}
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
      fullPath                                   | approvers                | result
      ${[groupApprover.fullPath]}                | ${existingGroupApprover} | ${false}
      ${[]}                                      | ${noExistingApprovers}   | ${false}
      ${[]}                                      | ${existingGroupApprover} | ${true}
      ${[groupApprover.fullPath]}                | ${noExistingApprovers}   | ${true}
      ${[groupApprover.fullPath, 'not present']} | ${existingGroupApprover} | ${true}
      ${['not present']}                         | ${noExistingApprovers}   | ${true}
      ${['not present']}                         | ${existingGroupApprover} | ${true}
    `(
      'return $result when fullPath and approvers length equal to $fullPath and $approvers.length',
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
      userApproversIds     | usernames                  | groupApproversIds     | groupPaths                  | approvers                 | result
      ${[]}                | ${[userApprover.username]} | ${[groupApprover.id]} | ${[]}                       | ${existingMixedApprovers} | ${false}
      ${[userApprover.id]} | ${[]}                      | ${[groupApprover.id]} | ${[]}                       | ${existingMixedApprovers} | ${false}
      ${[userApprover.id]} | ${[]}                      | ${[]}                 | ${[groupApprover.fullPath]} | ${existingMixedApprovers} | ${false}
      ${[]}                | ${[userApprover.username]} | ${[]}                 | ${[groupApprover.fullPath]} | ${existingMixedApprovers} | ${false}
      ${[]}                | ${[]}                      | ${[]}                 | ${[]}                       | ${noExistingApprovers}    | ${false}
      ${[]}                | ${[userApprover.username]} | ${[3]}                | ${[]}                       | ${existingMixedApprovers} | ${true}
      ${[userApprover.id]} | ${[]}                      | ${[3]}                | ${[]}                       | ${existingMixedApprovers} | ${true}
      ${[userApprover.id]} | ${[]}                      | ${[]}                 | ${['not present']}          | ${existingMixedApprovers} | ${true}
      ${[]}                | ${[userApprover.username]} | ${[]}                 | ${['not present']}          | ${existingMixedApprovers} | ${true}
      ${[userApprover.id]} | ${[]}                      | ${[]}                 | ${[groupApprover.fullPath]} | ${existingGroupApprover}  | ${true}
      ${[]}                | ${[userApprover.username]} | ${[]}                 | ${[groupApprover.fullPath]} | ${existingGroupApprover}  | ${true}
    `(
      'return $result when user_ids, usernames, groupIds, groupPaths and approvers length equal to $userApproversIds, $usernames, $groupApproversIds, $groupPaths and $approvers.length',
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

describe('actionHasType', () => {
  it.each`
    action                                              | type          | output
    ${{ key: 'value' }}                                 | ${ROLE_TYPE}  | ${false}
    ${{ [APPROVER_TYPE_DICT[ROLE_TYPE][0]]: 'value' }}  | ${USER_TYPE}  | ${false}
    ${{ [APPROVER_TYPE_DICT[USER_TYPE][0]]: 'value' }}  | ${GROUP_TYPE} | ${false}
    ${{ [APPROVER_TYPE_DICT[ROLE_TYPE][0]]: 'value' }}  | ${ROLE_TYPE}  | ${true}
    ${{ [APPROVER_TYPE_DICT[USER_TYPE][0]]: 'value' }}  | ${USER_TYPE}  | ${true}
    ${{ [APPROVER_TYPE_DICT[USER_TYPE][1]]: 'value' }}  | ${USER_TYPE}  | ${true}
    ${{ [APPROVER_TYPE_DICT[GROUP_TYPE][0]]: 'value' }} | ${GROUP_TYPE} | ${true}
    ${{ [APPROVER_TYPE_DICT[GROUP_TYPE][1]]: 'value' }} | ${GROUP_TYPE} | ${true}
  `('returns $output when action is $action and type is $type', ({ action, type, output }) => {
    expect(actionHasType(action, type)).toBe(output);
  });
});
