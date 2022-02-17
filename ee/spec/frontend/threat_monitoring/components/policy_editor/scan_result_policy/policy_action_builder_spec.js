import { GlFormInput, GlToken } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import PolicyActionBuilder from 'ee/threat_monitoring/components/policy_editor/scan_result_policy/policy_action_builder.vue';

const APPROVER_1 = {
  id: 1,
  name: 'name',
  state: 'active',
  username: 'username',
  web_url: '',
  avatar_url: '',
};

const APPROVER_2 = {
  id: 2,
  name: 'name2',
  state: 'active',
  username: 'username2',
  web_url: '',
  avatar_url: '',
};

const APPROVERS = [APPROVER_1, APPROVER_2];

const APPROVERS_IDS = APPROVERS.map((approver) => approver.id);

const ACTION = {
  approvals_required: 1,
  user_approvers_ids: APPROVERS_IDS,
};

describe('PolicyActionBuilder', () => {
  let wrapper;

  const factory = (propsData = {}) => {
    wrapper = mount(PolicyActionBuilder, {
      propsData: {
        initAction: ACTION,
        existingApprovers: APPROVERS,
        ...propsData,
      },
      provide: {
        projectId: '1',
      },
    });
  };

  const findApprovalsRequiredInput = () => wrapper.findComponent(GlFormInput);
  const findAllGlTokens = () => wrapper.findAllComponents(GlToken);

  it('renders approvals required form input, gl-tokens', async () => {
    factory();
    await nextTick();

    expect(findApprovalsRequiredInput().exists()).toBe(true);
    expect(findAllGlTokens().length).toBe(APPROVERS.length);
  });

  it('triggers an update when changing approvals required', async () => {
    factory();
    await nextTick();

    const approvalRequestPlusOne = ACTION.approvals_required + 1;
    const formInput = findApprovalsRequiredInput();

    await formInput.vm.$emit('input', approvalRequestPlusOne);

    expect(wrapper.emitted().changed).toEqual([
      [{ approvals_required: approvalRequestPlusOne, user_approvers_ids: APPROVERS_IDS }],
    ]);
  });

  it('removes one approver when triggering a gl-token', async () => {
    factory();
    await nextTick();

    const allGlTokens = findAllGlTokens();
    const glToken = allGlTokens.at(0);
    const approversLengthMinusOne = APPROVERS.length - 1;

    expect(allGlTokens.length).toBe(APPROVERS.length);

    await glToken.vm.$emit('close', { ...APPROVER_1, type: 'user' });

    expect(wrapper.emitted().changed).toEqual([
      [
        {
          approvals_required: ACTION.approvals_required,
          user_approvers_ids: [APPROVER_2.id],
          group_approvers_ids: [],
        },
      ],
    ]);
    expect(findAllGlTokens()).toHaveLength(approversLengthMinusOne);
  });
});
