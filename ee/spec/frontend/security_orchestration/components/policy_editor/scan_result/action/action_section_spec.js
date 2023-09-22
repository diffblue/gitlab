import { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { GROUP_TYPE, USER_TYPE, ROLE_TYPE } from 'ee/security_orchestration/constants';
import ActionSection from 'ee/security_orchestration/components/policy_editor/scan_result/action/action_section.vue';
import ActionApprovers from 'ee/security_orchestration/components/policy_editor/scan_result/action/action_approvers.vue';
import { APPROVER_TYPE_LIST_ITEMS } from 'ee/security_orchestration/components/policy_editor/scan_result/lib/actions';

describe('ActionSection', () => {
  let wrapper;

  const APPROVERS_IDS = [1, 2, 3];

  const MOCK_USER_APPROVERS = APPROVERS_IDS.map((id) => ({
    id,
    name: `name${id}`,
    username: `username${id}`,
    type: USER_TYPE,
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
    type: 'require_approval',
    user_approvers_ids: APPROVERS_IDS,
  };

  const EXISTING_GROUP_ACTION = {
    approvals_required: 1,
    type: 'require_approval',
    group_approvers_ids: APPROVERS_IDS,
  };

  const EXISTING_MIXED_ACTION = {
    approvals_required: 1,
    type: 'require_approval',
    user_approvers_ids: APPROVERS_IDS,
    group_approvers_ids: APPROVERS_IDS,
  };

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMount(ActionSection, {
      propsData: {
        initAction: DEFAULT_ACTION,
        existingApprovers: {},
        ...propsData,
      },
      provide: {
        namespaceId: '1',
      },
    });
  };

  const findActionApprover = () => wrapper.findComponent(ActionApprovers);
  const findAllActionApprovers = () => wrapper.findAllComponents(ActionApprovers);
  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);

  const emit = async (event, value) => {
    findActionApprover().vm.$emit(event, value);
    await nextTick();
  };

  describe('default', () => {
    beforeEach(createWrapper);

    it('renders', () => {
      expect(findActionApprover().props()).toEqual({
        approverIndex: 0,
        availableTypes: APPROVER_TYPE_LIST_ITEMS,
        approvalsRequired: 1,
        errors: [],
        existingApprovers: {},
        numOfApproverTypes: 1,
        approverType: '',
      });
    });

    it('creates a new approver on "addApproverType"', async () => {
      expect(findAllActionApprovers()).toHaveLength(1);
      await emit('addApproverType');
      expect(findAllActionApprovers()).toHaveLength(2);
    });

    it('does not render alert', () => {
      expect(findAllAlerts()).toHaveLength(0);
    });

    it('emits "updateApprovers" with the appropriate values on "updateApprover"', async () => {
      await emit('updateApprovers', { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] });
      expect(wrapper.emitted('updateApprovers')[1]).toEqual([
        { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] },
      ]);
    });

    it('emits "changed" with the appropriate values on "updateApprover"', async () => {
      await emit('updateApprovers', { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] });
      expect(wrapper.emitted('changed')[1]).toEqual([
        {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers_ids: [1],
        },
      ]);
    });

    it('emits "changed" with the appropriate values on "updateApprovalsRequired"', async () => {
      expect(findActionApprover().props('approvalsRequired')).toBe(1);
      await emit('updateApprovalsRequired', 2);
      expect(wrapper.emitted('changed')[1]).toEqual([
        {
          approvals_required: 2,
          type: 'require_approval',
        },
      ]);
    });
  });

  describe('errors', () => {
    it('renders the alert when there is an error', () => {
      const error = { title: 'Error', message: 'Something went wrong' };
      createWrapper({ errors: [error] });
      const allAlerts = findAllAlerts();
      expect(allAlerts).toHaveLength(1);
      expect(allAlerts.at(0).props()).toMatchObject({
        title: error.title,
        dismissible: false,
      });
      expect(allAlerts.at(0).text()).toBe(error.message);
    });
  });

  describe('update approver type', () => {
    describe('initial selection', () => {
      it('updates the approver type', async () => {
        createWrapper();
        await nextTick();
        expect(findActionApprover().props('availableTypes')).toEqual(APPROVER_TYPE_LIST_ITEMS);
        await emit('updateApproverType', { newApproverType: USER_TYPE });
        expect(findActionApprover().props('availableTypes')).toEqual(
          APPROVER_TYPE_LIST_ITEMS.filter((t) => t.value !== USER_TYPE),
        );
      });
    });

    describe('change approver type', () => {
      beforeEach(async () => {
        createWrapper();
        await nextTick();
        await emit('updateApproverType', { newApproverType: USER_TYPE });
      });

      const changeApproverType = async () => {
        await emit('updateApproverType', {
          oldApproverType: USER_TYPE,
          newApproverType: GROUP_TYPE,
        });
      };

      it('adds the old type back into the list of available types', async () => {
        await changeApproverType();
        expect(findActionApprover().props('availableTypes')).toEqual(
          APPROVER_TYPE_LIST_ITEMS.filter((t) => t.value !== GROUP_TYPE),
        );
      });

      it('removes existing approvers of the old type', async () => {
        await emit('updateApprovers', { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] });
        expect(wrapper.emitted('changed')[1]).toEqual([
          {
            approvals_required: 1,
            type: 'require_approval',
            user_approvers_ids: [1],
          },
        ]);
        await changeApproverType();
        expect(wrapper.emitted('changed')[2]).toEqual([
          {
            approvals_required: 1,
            type: 'require_approval',
          },
        ]);
      });

      it('emits "updateApprovers" with the appropriate values', async () => {
        await emit('updateApprovers', { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] });
        expect(wrapper.emitted('updateApprovers')[1]).toEqual([
          { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] },
        ]);
        await changeApproverType();
        expect(wrapper.emitted('updateApprovers')[2]).toEqual([{}]);
      });
    });
  });

  describe('remove approver type', () => {
    beforeEach(async () => {
      createWrapper();
      await nextTick();
      await emit('updateApproverType', { newApproverType: USER_TYPE });
    });

    const removeApproverType = async () => {
      await emit('removeApproverType', USER_TYPE);
    };

    it('adds the old type back into the list of available types', async () => {
      expect(findActionApprover().props('availableTypes')).toEqual(
        APPROVER_TYPE_LIST_ITEMS.filter((t) => t.value !== USER_TYPE),
      );
      await emit('addApproverType');
      findAllActionApprovers().at(0).vm.$emit('removeApproverType', USER_TYPE);
      await nextTick();
      expect(findActionApprover().props('availableTypes')).toEqual(
        expect.arrayContaining(APPROVER_TYPE_LIST_ITEMS),
      );
    });

    it('removes existing approvers of the old type', async () => {
      await emit('updateApprovers', { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] });
      expect(wrapper.emitted('changed')[1]).toEqual([
        {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers_ids: [1],
        },
      ]);
      await removeApproverType();
      expect(wrapper.emitted('changed')[2]).toEqual([
        {
          approvals_required: 1,
          type: 'require_approval',
        },
      ]);
    });

    it('emits "updateApprovers" with the appropriate values', async () => {
      await emit('updateApprovers', { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] });
      expect(wrapper.emitted('updateApprovers')[1]).toEqual([
        { [USER_TYPE]: [MOCK_USER_APPROVERS[0]] },
      ]);
      await removeApproverType();
      expect(wrapper.emitted('updateApprovers')[2]).toEqual([{}]);
    });
  });

  describe('existing user approvers', () => {
    beforeEach(() => {
      createWrapper({
        initAction: EXISTING_USER_ACTION,
        existingApprovers: { [USER_TYPE]: USER_APPROVERS },
      });
    });

    it('renders the user select when there are existing user approvers', () => {
      expect(findAllActionApprovers()).toHaveLength(1);
      expect(findActionApprover().props('approverType')).toBe(USER_TYPE);
    });
  });

  describe('existing group approvers', () => {
    beforeEach(() => {
      createWrapper({
        initAction: EXISTING_GROUP_ACTION,
        existingApprovers: { [GROUP_TYPE]: GROUP_APPROVERS },
      });
    });

    it('renders the group select when there are existing group approvers', () => {
      expect(findAllActionApprovers()).toHaveLength(1);
      expect(findActionApprover().props('approverType')).toBe(GROUP_TYPE);
    });
  });

  describe('existing mixed approvers', () => {
    beforeEach(() => {
      createWrapper({
        initAction: EXISTING_MIXED_ACTION,
        existingApprovers: { [GROUP_TYPE]: [...GROUP_APPROVERS], [USER_TYPE]: [...USER_APPROVERS] },
      });
    });

    it('renders the user select with only the user approvers', () => {
      expect(findAllActionApprovers()).toHaveLength(2);
      expect(findAllActionApprovers().at(0).props('approverType')).toBe(GROUP_TYPE);
      expect(findAllActionApprovers().at(1).props('approverType')).toBe(USER_TYPE);
    });
  });

  describe('updates role approvers', () => {
    it('updates role approvers with new values', () => {
      createWrapper({
        initAction: { ...DEFAULT_ACTION, role_approvers: ['developer'] },
        existingApprovers: { [ROLE_TYPE]: ['owner'] },
      });
      expect(wrapper.emitted('changed')).toEqual([
        [{ ...DEFAULT_ACTION, role_approvers: ['developer'] }],
      ]);
      expect(wrapper.emitted('updateApprovers')).toEqual([[{ [ROLE_TYPE]: ['developer'] }]]);
    });

    it('updates role approvers with no values', () => {
      createWrapper({
        initAction: DEFAULT_ACTION,
        existingApprovers: { [ROLE_TYPE]: ['owner'] },
      });
      expect(wrapper.emitted('changed')).toEqual([[DEFAULT_ACTION]]);
      expect(wrapper.emitted('updateApprovers')).toEqual([[{}]]);
    });
  });
});
