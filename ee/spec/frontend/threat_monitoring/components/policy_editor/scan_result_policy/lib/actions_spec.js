import {
  groupIds,
  userIds,
  groupApprovers,
  decomposeApprovers,
} from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/lib/actions';

// As returned by endpoints based on API::Entities::UserBasic
const userApprover = {
  id: 1,
  name: null,
  state: null,
  username: null,
  avatar_url: null,
  web_url: null,
};

// As returned by endpoints based on API::Entities::PublicGroupDetails
const groupApprover = {
  id: 2,
  name: null,
  full_name: null,
  full_path: null,
  avatar_url: null,
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
        {
          avatar_url: null,
          id: userApprover.id,
          name: null,
          state: null,
          type: 'user',
          username: null,
          web_url: null,
        },
        {
          avatar_url: null,
          full_name: null,
          full_path: null,
          id: groupApprover.id,
          name: null,
          type: 'group',
          web_url: null,
        },
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
    expect(groupApprovers([groupApprover])).toStrictEqual([
      {
        avatar_url: null,
        full_name: null,
        full_path: null,
        id: groupApprover.id,
        name: null,
        type: 'group',
        web_url: null,
      },
    ]);
  });

  it('sets user as a type for user related approvers', () => {
    expect(groupApprovers([userApprover])).toStrictEqual([
      {
        avatar_url: null,
        id: userApprover.id,
        name: null,
        state: null,
        type: 'user',
        username: null,
        web_url: null,
      },
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
