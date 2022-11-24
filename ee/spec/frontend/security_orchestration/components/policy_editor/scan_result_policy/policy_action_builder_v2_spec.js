import { GlForm, GlFormInput, GlListbox, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_builder_v2.vue';
import GroupSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/group_select.vue';
import UserSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/user_select.vue';
import {
  GROUP_TYPE,
  USER_TYPE,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/actions';

const APPROVERS_IDS = [1, 2, 3];

const MOCK_USER_APPROVERS = APPROVERS_IDS.map((id) => ({
  id,
  name: `name${id}`,
  username: `username${id}`,
  webUrl: '',
  avatarUrl: '',
}));

const MOCK_GROUP_APPROVERS = APPROVERS_IDS.map((id) => ({
  id,
  name: `group-name${id}`,
  fullName: `group-name${id}`,
  fullPath: `path/to/group${id}`,
  webUrl: '',
  avatarUrl: '',
}));

const USER_APPROVERS = [MOCK_USER_APPROVERS[0], MOCK_USER_APPROVERS[1]];

const GROUP_APPROVERS = [MOCK_GROUP_APPROVERS[0], MOCK_GROUP_APPROVERS[1]];

const DEFAULT_ACTION = {
  approvals_required: 1,
  type: 'require_approval',
};

const EXISTING_USER_ACTION = {
  approvals_required: 1,
  user_approvers_ids: APPROVERS_IDS,
};

const EXISTING_GROUP_ACTION = {
  approvals_required: 1,
  group_approvers_ids: APPROVERS_IDS,
};

const EXISTING_MIXED_ACTION = {
  approvals_required: 1,
  user_approvers_ids: APPROVERS_IDS,
  group_approvers_ids: APPROVERS_IDS,
};

describe('PolicyActionBuilder', () => {
  let wrapper;

  const factory = (propsData = {}) => {
    wrapper = shallowMount(PolicyActionBuilder, {
      propsData: {
        initAction: DEFAULT_ACTION,
        existingApprovers: [],
        ...propsData,
      },
      provide: {
        namespaceId: '1',
        namespacePath: 'path/to/project',
        namespaceType: 'project',
      },
      stubs: {
        GlForm,
        GlSprintf,
      },
    });
  };

  const findApprovalsRequiredInput = () => wrapper.findComponent(GlFormInput);
  const findApproverTypeDropdown = () => wrapper.findComponent(GlListbox);
  const findGroupSelect = () => wrapper.findComponent(GroupSelect);
  const findUserSelect = () => wrapper.findComponent(UserSelect);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(factory);

    it('triggers an update when changing number of approvals required', async () => {
      const approvalRequestPlusOne = DEFAULT_ACTION.approvals_required + 1;
      const formInput = findApprovalsRequiredInput();

      await formInput.vm.$emit('update', approvalRequestPlusOne);

      expect(wrapper.emitted('changed')).toEqual([
        [{ ...DEFAULT_ACTION, approvals_required: approvalRequestPlusOne }],
      ]);
    });

    it('renders the user select when the "user" type approver is selected', async () => {
      expect(findUserSelect().exists()).toBe(false);
      await findApproverTypeDropdown().vm.$emit('select', USER_TYPE);
      expect(findUserSelect().exists()).toBe(true);
    });

    it('does not the group select when the "user" type approver is selected', async () => {
      expect(findGroupSelect().exists()).toBe(false);
      await findApproverTypeDropdown().vm.$emit('select', USER_TYPE);
      expect(findGroupSelect().exists()).toBe(false);
    });

    it('does not render the user select when the "group" type approver is selected', async () => {
      expect(findUserSelect().exists()).toBe(false);
      await findApproverTypeDropdown().vm.$emit('select', 'group');
      expect(findUserSelect().exists()).toBe(false);
    });

    it('triggers an update when changing available group approvers', async () => {
      const newGroup = { id: 1, type: GROUP_TYPE };

      await findApproverTypeDropdown().vm.$emit('select', GROUP_TYPE);
      await findGroupSelect().vm.$emit('updateSelectedApprovers', [newGroup]);

      expect(wrapper.emitted()).toEqual({
        approversUpdated: [[[newGroup]]],
        changed: [[{ ...DEFAULT_ACTION, group_approvers_ids: [newGroup.id] }]],
      });
    });

    it('triggers an update when changing available user approvers', async () => {
      const newUser = { id: 1, type: USER_TYPE };

      await findApproverTypeDropdown().vm.$emit('select', USER_TYPE);
      await findUserSelect().vm.$emit('updateSelectedApprovers', [newUser]);

      expect(wrapper.emitted()).toEqual({
        approversUpdated: [[[newUser]]],
        changed: [[{ ...DEFAULT_ACTION, user_approvers_ids: [newUser.id] }]],
      });
    });
  });

  describe('existing user approvers', () => {
    beforeEach(() => {
      factory({
        initAction: EXISTING_USER_ACTION,
        existingApprovers: USER_APPROVERS,
      });
    });

    it('renders the user select when there are existing user approvers', () => {
      expect(findUserSelect().exists()).toBe(true);
    });
  });

  describe('existing group approvers', () => {
    beforeEach(() => {
      factory({
        initAction: EXISTING_GROUP_ACTION,
        existingApprovers: GROUP_APPROVERS,
      });
    });

    it('renders the group select when there are existing group approvers', () => {
      expect(findGroupSelect().exists()).toBe(true);
    });
  });

  describe('existing mixed approvers', () => {
    beforeEach(() => {
      factory({
        initAction: EXISTING_MIXED_ACTION,
        existingApprovers: [...GROUP_APPROVERS, ...USER_APPROVERS],
      });
    });

    it('renders the user select with only the user approvers', () => {
      expect(findUserSelect().exists()).toBe(true);
      expect(findUserSelect().props('existingApprovers')).toEqual([
        { ...USER_APPROVERS[0], type: USER_TYPE, value: 'gid://gitlab/User/1' },
        { ...USER_APPROVERS[1], type: USER_TYPE, value: 'gid://gitlab/User/2' },
      ]);
    });

    // TODO create test for renders the group select with only the group approvers as part of https://gitlab.com/gitlab-org/gitlab/-/issues/377865
  });
});
