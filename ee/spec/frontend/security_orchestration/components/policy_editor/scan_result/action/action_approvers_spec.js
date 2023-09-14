import { nextTick } from 'vue';
import { GlForm, GlFormInput, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import { GROUP_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';
import ActionApprovers from 'ee/security_orchestration/components/policy_editor/scan_result/action/action_approvers.vue';
import GroupSelect from 'ee/security_orchestration/components/policy_editor/scan_result/action/group_select.vue';
import UserSelect from 'ee/security_orchestration/components/policy_editor/scan_result/action/user_select.vue';
import {
  APPROVER_TYPE_LIST_ITEMS,
  DEFAULT_APPROVER_DROPDOWN_TEXT,
  getDefaultHumanizedTemplate,
  MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE,
} from 'ee/security_orchestration/components/policy_editor/scan_result/lib/actions';

const DEFAULT_ACTION = {
  approvals_required: 1,
  type: 'require_approval',
};

describe('ActionApprovers', () => {
  let wrapper;

  const factory = ({ propsData = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(ActionApprovers, {
      propsData: {
        availableTypes: APPROVER_TYPE_LIST_ITEMS,
        approverIndex: 0,
        approvalsRequired: 1,
        existingApprovers: {},
        numOfApproverTypes: 1,
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
        SectionLayout,
        ...stubs,
      },
    });
  };

  const findApprovalsRequiredInput = () => wrapper.findComponent(GlFormInput);
  const findApproverTypeDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGroupSelect = () => wrapper.findComponent(GroupSelect);
  const findUserSelect = () => wrapper.findComponent(UserSelect);
  const findAddButton = () => wrapper.findByTestId('add-approver');
  const findSectionLayout = () => wrapper.findComponent(SectionLayout);
  const findMessage = () => wrapper.findComponent(GlSprintf);

  describe('single type', () => {
    beforeEach(factory);

    it('renders the approver type dropdown with the correct props', () => {
      expect(findApproverTypeDropdown().props()).toMatchObject({
        disabled: false,
        selected: [],
        toggleText: DEFAULT_APPROVER_DROPDOWN_TEXT,
      });
    });

    it('renders the number of approvers input with a valid state', () => {
      const approvalsRequiredInput = findApprovalsRequiredInput();
      expect(approvalsRequiredInput.exists()).toBe(true);
      expect(approvalsRequiredInput.attributes('state')).toBe('true');
    });

    it('renders the add button', () => {
      expect(findAddButton().exists()).toBe(true);
    });

    it('triggers an update when adding a new type', async () => {
      expect(wrapper.emitted('addApproverType')).toEqual(undefined);
      await findAddButton().vm.$emit('click');
      expect(wrapper.emitted('addApproverType')).toEqual([[]]);
    });

    it('does not render the remove button', () => {
      expect(findSectionLayout().props('showRemoveButton')).toBe(false);
    });

    it('does not render the user select when the "user" type approver is not selected', () => {
      expect(findUserSelect().exists()).toBe(false);
    });

    it('does not render the group select when the "group" type approver is not selected', () => {
      expect(findGroupSelect().exists()).toBe(false);
    });

    it('triggers an update when changing number of approvals required', async () => {
      const approvalRequestPlusOne = DEFAULT_ACTION.approvals_required + 1;
      const formInput = findApprovalsRequiredInput();

      await formInput.vm.$emit('update', approvalRequestPlusOne);

      expect(wrapper.emitted('updateApprovalsRequired')).toEqual([[approvalRequestPlusOne]]);
    });

    it('triggers an update when changing the approver type', async () => {
      await findApproverTypeDropdown().vm.$emit('select', GROUP_TYPE);

      expect(wrapper.emitted()).toEqual({
        updateApproverType: [[{ newApproverType: GROUP_TYPE, oldApproverType: '' }]],
      });
    });
  });

  describe('errors', () => {
    it('renders the number of approvers input with an invalid state', () => {
      factory({ propsData: { errors: [{ field: 'approvers_ids' }] } });
      const approvalsRequiredInput = findApprovalsRequiredInput();
      expect(approvalsRequiredInput.exists()).toBe(true);
      expect(approvalsRequiredInput.attributes('state')).toBe(undefined);
    });

    it('renders the approver dropdown with an invalid state', () => {
      factory({ propsData: { approverType: USER_TYPE, errors: [{ field: 'approvers_ids' }] } });
      expect(findUserSelect().props('state')).toBe(false);
    });
  });

  describe('selected approver types', () => {
    it('renders the approver type dropdown with the correct props', async () => {
      factory({ propsData: { approverType: USER_TYPE } });
      await nextTick();
      const text = APPROVER_TYPE_LIST_ITEMS.find((v) => v.value === USER_TYPE)?.text;
      expect(findApproverTypeDropdown().props()).toMatchObject({
        disabled: false,
        selected: text,
        toggleText: text,
      });
    });

    it('renders the user select with the correct props when the "user" type approver is selected', async () => {
      factory({ propsData: { approverType: USER_TYPE } });
      await nextTick();
      expect(findUserSelect().exists()).toBe(true);
      expect(findUserSelect().props('state')).toBe(true);
    });

    it('renders the group select when the "group" type approver is selected', async () => {
      factory({ propsData: { approverType: GROUP_TYPE } });
      await nextTick();
      expect(findGroupSelect().exists()).toBe(true);
    });

    it('triggers an update when changing available user approvers', async () => {
      factory({ propsData: { approverType: USER_TYPE } });
      await nextTick();
      const newUser = { id: 1, type: USER_TYPE };

      await findUserSelect().vm.$emit('updateSelectedApprovers', [newUser]);

      expect(wrapper.emitted()).toEqual({
        updateApprovers: [[{ [USER_TYPE]: [{ id: newUser.id, type: USER_TYPE }] }]],
      });
    });

    it('triggers an update when changing available group approvers', async () => {
      factory({ propsData: { approverType: GROUP_TYPE } });
      await nextTick();
      const newGroup = { id: 1, type: GROUP_TYPE };

      await findGroupSelect().vm.$emit('updateSelectedApprovers', [newGroup]);

      expect(wrapper.emitted()).toEqual({
        updateApprovers: [[{ [GROUP_TYPE]: [{ id: newGroup.id, type: GROUP_TYPE }] }]],
      });
    });
  });

  describe('multiple types', () => {
    beforeEach(() => {
      factory({
        propsData: { approverIndex: 1, numOfApproverTypes: 3 },
      });
    });

    it('triggers an update when removing a new type', async () => {
      expect(wrapper.emitted('removeApproverType')).toEqual(undefined);
      await findSectionLayout().vm.$emit('remove');
      expect(wrapper.emitted('removeApproverType')).toEqual([['']]);
    });

    it('does not render the add button for the last type', () => {
      expect(findAddButton().exists()).toBe(false);
    });

    it('renders the remove button', () => {
      expect(findSectionLayout().props('showRemoveButton')).toBe(true);
    });
  });

  describe('message', () => {
    it('renders the correct message for the first type added', async () => {
      factory({ stubs: { GlSprintf: true, SectionLayout: true } });
      await nextTick();
      expect(findMessage().attributes('message')).toBe(getDefaultHumanizedTemplate(1));
    });

    it('renders the correct text for the non-first type', async () => {
      factory({
        propsData: { approverIndex: 1, numOfApproverTypes: 2 },
        stubs: { GlSprintf: true, SectionLayout: true },
      });
      await nextTick();
      expect(findMessage().attributes('message')).toBe(MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE);
    });
  });
});
