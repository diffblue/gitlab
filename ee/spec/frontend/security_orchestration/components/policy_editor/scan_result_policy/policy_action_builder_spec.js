import { GlFormInput } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import PolicyActionBuilder from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_action_builder.vue';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import ApproversList from 'ee/approvals/components/approvers_list.vue';
import ApproversListItem from 'ee/approvals/components/approvers_list_item.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

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

const NEW_APPROVER = {
  id: 3,
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
    mock.onGet('/api/undefined/projects/1/users').reply(HTTP_STATUS_OK);
    mock.onGet('/api/undefined/projects/1/groups.json').reply(HTTP_STATUS_OK);
  });

  afterEach(() => {
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

    await formInput.vm.$emit('input', approvalRequestPlusOne);

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

    await approversItem.vm.$emit('remove', { ...APPROVER_1, type: 'user' });

    expect(wrapper.emitted().changed).toEqual([
      [
        {
          approvals_required: ACTION.approvals_required,
          user_approvers_ids: [APPROVER_2.id],
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
          user_approvers_ids: [APPROVER_1.id, APPROVER_2.id, NEW_APPROVER.id],
        },
      ],
    ]);
    expect(findAllApproversItem()).toHaveLength(approversLengthPlusOne);
  });
});
