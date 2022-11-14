import { GlForm, GlFormInput, GlListbox, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_builder_v2.vue';
import UserSelect from 'ee/security_orchestration/components/policy_editor/scan_result_policy/user_select.vue';
import { USER_TYPE } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/actions';

const APPROVERS_IDS = [1, 2, 3];

const MOCK_APPROVERS = APPROVERS_IDS.map((id) => ({
  id,
  name: `name${id}`,
  state: 'active',
  username: `username${id}`,
  web_url: '',
  avatar_url: '',
}));

const APPROVERS = [MOCK_APPROVERS[0], MOCK_APPROVERS[1]];

const DEFAULT_ACTION = {
  approvals_required: 1,
  type: 'require_approval',
  user_approvers_ids: [],
};

const EXISTING_ACTION = {
  approvals_required: 1,
  user_approvers_ids: APPROVERS_IDS,
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

    it('renders the users select when the "user" type approver is selected', async () => {
      expect(findUserSelect().exists()).toBe(false);
      await findApproverTypeDropdown().vm.$emit('select', USER_TYPE);
      expect(findUserSelect().exists()).toBe(true);
    });

    it('does not render the users select when the "group" type approver is selected', async () => {
      expect(findUserSelect().exists()).toBe(false);
      await findApproverTypeDropdown().vm.$emit('select', 'group');
      expect(findUserSelect().exists()).toBe(false);
    });

    it('triggers an update when changing available approvers', async () => {
      const newUser = { id: 1, type: USER_TYPE };

      await findApproverTypeDropdown().vm.$emit('select', USER_TYPE);
      await findUserSelect().vm.$emit('updateSelectedApprovers', [newUser]);

      expect(wrapper.emitted()).toEqual({
        approversUpdated: [[[newUser]]],
        changed: [[{ ...DEFAULT_ACTION, user_approvers_ids: [newUser.id] }]],
      });
    });
  });

  describe('existing approvers', () => {
    beforeEach(() => {
      factory({
        initAction: EXISTING_ACTION,
        existingApprovers: APPROVERS,
      });
    });

    it('renders the users select when there are existing user approvers', () => {
      expect(findUserSelect().exists()).toBe(true);
    });
  });
});
