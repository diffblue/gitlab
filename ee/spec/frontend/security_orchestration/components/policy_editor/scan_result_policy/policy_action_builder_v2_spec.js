import { GlFormInput } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_builder_v2.vue';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import ApproversList from 'ee/approvals/components/approvers_list.vue';
import ApproversListItem from 'ee/approvals/components/approvers_list_item.vue';
import axios from '~/lib/utils/axios_utils';

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
const NEW_APPROVER = MOCK_APPROVERS[2];

const ACTION = {
  approvals_required: 1,
  user_approvers_ids: APPROVERS_IDS,
};

describe('PolicyActionBuilder', () => {
  let wrapper;
  let mock;

  const factory = (propsData = {}) => {
    wrapper = mount(PolicyActionBuilder, {
      propsData: {
        initAction: ACTION,
        existingApprovers: APPROVERS,
        ...propsData,
      },
      provide: {
        namespaceId: '1',
        namespaceType: 'project',
      },
    });
  };

  const findApprovalsRequiredInput = () => wrapper.findComponent(GlFormInput);
  const findApproversList = () => wrapper.findComponent(ApproversList);
  const findAddApproversSelect = () => wrapper.findComponent(ApproversSelect);
  const findAllApproversItem = () => wrapper.findAllComponents(ApproversListItem);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('/api/undefined/projects/1/users').reply(200);
    mock.onGet('/api/undefined/projects/1/groups.json').reply(200);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  it('renders approvals required form input, approvers list and approvers select', async () => {
    factory();
    await nextTick();

    expect(findApprovalsRequiredInput().exists()).toBe(true);
    expect(findApproversList().exists()).toBe(true);
    expect(findAddApproversSelect().exists()).toBe(true);
  });

  it('triggers an update when changing approvals required', async () => {
    factory();
    await nextTick();

    const approvalRequestPlusOne = ACTION.approvals_required + 1;
    const formInput = findApprovalsRequiredInput();

    await formInput.vm.$emit('update', approvalRequestPlusOne);

    expect(wrapper.emitted().changed).toEqual([
      [{ approvals_required: approvalRequestPlusOne, user_approvers_ids: APPROVERS_IDS }],
    ]);
  });

  it('removes one approver when triggering a remove button click', async () => {
    factory();
    await nextTick();

    const allApproversItems = findAllApproversItem();
    const approversItem = allApproversItems.at(0);
    const approversLengthMinusOne = APPROVERS.length - 1;

    expect(allApproversItems.length).toBe(APPROVERS.length);

    await approversItem.vm.$emit('remove', { ...APPROVERS[1], type: 'user' });

    expect(wrapper.emitted().changed).toEqual([
      [
        {
          approvals_required: ACTION.approvals_required,
          user_approvers_ids: [APPROVERS[1].id],
        },
      ],
    ]);
    expect(findAllApproversItem()).toHaveLength(approversLengthMinusOne);
  });

  it('adds one approver when triggering a new user is selected', async () => {
    factory();
    await nextTick();

    const allApproversItems = findAllApproversItem();
    const approversLengthPlusOne = APPROVERS.length + 1;

    expect(allApproversItems.length).toBe(APPROVERS.length);

    await findAddApproversSelect().vm.$emit('input', [{ ...NEW_APPROVER, type: 'user' }]);

    expect(wrapper.emitted().changed).toEqual([
      [
        {
          approvals_required: ACTION.approvals_required,
          user_approvers_ids: [APPROVERS[0].id, APPROVERS[1].id, NEW_APPROVER.id],
        },
      ],
    ]);
    expect(findAllApproversItem()).toHaveLength(approversLengthPlusOne);
  });
});
