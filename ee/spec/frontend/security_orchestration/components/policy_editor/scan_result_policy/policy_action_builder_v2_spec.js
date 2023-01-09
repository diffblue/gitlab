import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_builder_v2.vue';
import PolicyActionApprovers from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_approvers.vue';
import {
  APPROVER_TYPE_LIST_ITEMS,
  GROUP_TYPE,
  USER_TYPE,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/actions';

describe('PolicyActionBuilder', () => {
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

  const DEFAULT_ACTION = {
    approvals_required: 1,
    type: 'require_approval',
  };

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMount(PolicyActionBuilder, {
      propsData: {
        initAction: DEFAULT_ACTION,
        existingApprovers: [],
        ...propsData,
      },
      provide: {
        namespaceId: '1',
      },
    });
  };

  const findActionApprovers = () => wrapper.findComponent(PolicyActionApprovers);
  const findAllActionApprovers = () => wrapper.findAllComponents(PolicyActionApprovers);

  const emit = async (event, value) => {
    findActionApprovers().vm.$emit(event, value);
    await nextTick();
  };

  describe('default', () => {
    beforeEach(createWrapper);

    it('renders', () => {
      expect(findActionApprovers().props()).toEqual({
        approverIndex: 0,
        approverTypes: APPROVER_TYPE_LIST_ITEMS,
        approvalsRequired: 1,
        existingApprovers: [],
        numOfApproverTypes: 1,
      });
    });

    it('creates a new approver on "addApproverType"', async () => {
      expect(findAllActionApprovers()).toHaveLength(1);
      await emit('addApproverType');
      expect(findAllActionApprovers()).toHaveLength(2);
    });

    it('emits "updateApprovers" with the appropriate values on "updateApprover"', async () => {
      expect(wrapper.emitted('updateApprovers')).toBeUndefined();
      await emit('updateApprovers', [MOCK_USER_APPROVERS[0]]);
      expect(wrapper.emitted('updateApprovers')[0]).toEqual([[MOCK_USER_APPROVERS[0]]]);
    });

    it('emits "changed" with the appropriate values on "updateApprover"', async () => {
      expect(wrapper.emitted('changed')).toBeUndefined();
      await emit('updateApprovers', [MOCK_USER_APPROVERS[0]]);
      expect(wrapper.emitted('changed')[0]).toEqual([
        {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers_ids: [1],
        },
      ]);
    });

    it('emits "changed" with the appropriate values on "updateApprovalsRequired"', async () => {
      expect(findActionApprovers().props('approvalsRequired')).toBe(1);
      expect(wrapper.emitted('changed')).toBeUndefined();
      await emit('updateApprovalsRequired', 2);
      expect(wrapper.emitted('changed')[0]).toEqual([
        {
          approvals_required: 2,
          type: 'require_approval',
        },
      ]);
    });
  });

  describe('update approver type', () => {
    describe('initial selection', () => {
      it('updates the approver type', async () => {
        createWrapper();
        await nextTick();
        expect(findActionApprovers().props('approverTypes')).toEqual(APPROVER_TYPE_LIST_ITEMS);
        await emit('updateApproverType', { newApproverType: USER_TYPE });
        expect(findActionApprovers().props('approverTypes')).toEqual(
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
        expect(findActionApprovers().props('approverTypes')).toEqual(
          APPROVER_TYPE_LIST_ITEMS.filter((t) => t.value !== GROUP_TYPE),
        );
      });

      it('removes existing approvers of the old type', async () => {
        await emit('updateApprovers', [MOCK_USER_APPROVERS[0]]);
        expect(wrapper.emitted('changed')[0]).toEqual([
          {
            approvals_required: 1,
            type: 'require_approval',
            user_approvers_ids: [1],
          },
        ]);
        await changeApproverType();
        expect(wrapper.emitted('changed')[1]).toEqual([
          {
            approvals_required: 1,
            type: 'require_approval',
          },
        ]);
      });

      it('emits "updateApprovers" with the appropriate values', async () => {
        await emit('updateApprovers', [MOCK_USER_APPROVERS[0]]);
        expect(wrapper.emitted('updateApprovers')[0]).toEqual([[MOCK_USER_APPROVERS[0]]]);
        await changeApproverType();
        expect(wrapper.emitted('updateApprovers')[1]).toEqual([[]]);
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
      expect(findActionApprovers().props('approverTypes')).toEqual(
        APPROVER_TYPE_LIST_ITEMS.filter((t) => t.value !== USER_TYPE),
      );
      await emit('addApproverType');
      findAllActionApprovers().at(0).vm.$emit('removeApproverType', USER_TYPE);
      await nextTick();
      expect(findActionApprovers().props('approverTypes')).toEqual(
        expect.arrayContaining(APPROVER_TYPE_LIST_ITEMS),
      );
    });

    it('removes existing approvers of the old type', async () => {
      await emit('updateApprovers', [MOCK_USER_APPROVERS[0]]);
      expect(wrapper.emitted('changed')[0]).toEqual([
        {
          approvals_required: 1,
          type: 'require_approval',
          user_approvers_ids: [1],
        },
      ]);
      await removeApproverType();
      expect(wrapper.emitted('changed')[1]).toEqual([
        {
          approvals_required: 1,
          type: 'require_approval',
        },
      ]);
    });

    it('emits "updateApprovers" with the appropriate values', async () => {
      await emit('updateApprovers', [MOCK_USER_APPROVERS[0]]);
      expect(wrapper.emitted('updateApprovers')[0]).toEqual([[MOCK_USER_APPROVERS[0]]]);
      await removeApproverType();
      expect(wrapper.emitted('updateApprovers')[1]).toEqual([[]]);
    });
  });
});
