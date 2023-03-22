import { GlAvatar, GlButton } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { sprintf, s__ } from '~/locale';
import AccessDropdown from '~/projects/settings/components/access_dropdown.vue';
import { createStore } from 'ee/protected_environments/store/edit';
import AddRuleModal from 'ee/protected_environments/add_rule_modal.vue';
import AddApprovers from 'ee/protected_environments/add_approvers.vue';
import EditProtectedEnvironmentRulesCard from 'ee/protected_environments/edit_protected_environment_rules_card.vue';
import EditProtectedEnvironmentsList from 'ee/protected_environments/edit_protected_environments_list.vue';
import ProtectedEnvironments from 'ee/protected_environments/protected_environments.vue';
import { DEPLOYER_RULE_KEY, APPROVER_RULE_KEY } from 'ee/protected_environments/constants';
import { MAINTAINER_ACCESS_LEVEL, DEVELOPER_ACCESS_LEVEL } from './constants';

const DEFAULT_ENVIRONMENTS = [
  {
    name: 'staging',
    deploy_access_levels: [
      {
        id: 1,
        access_level: DEVELOPER_ACCESS_LEVEL,
        access_level_description: 'Deployers + Maintainers',
        group_id: null,
        user_id: null,
      },
      {
        id: 2,
        group_id: 1,
        group_inheritance_type: '1',
        access_level_description: 'Some group',
        access_level: null,
        user_id: null,
      },
      {
        id: 3,
        user_id: 1,
        access_level_description: 'Some user',
        access_level: null,
        group_id: null,
      },
    ],
    approval_rules: [
      {
        id: 1,
        access_level: 30,
        access_level_description: 'Deployers + Maintainers',
        group_id: null,
        user_id: null,
        required_approvals: 1,
      },
      {
        id: 2,
        group_id: 1,
        group_inheritance_type: '1',
        access_level_description: 'Some group',
        access_level: null,
        user_id: null,
        required_approvals: 1,
      },
      {
        id: 3,
        user_id: 1,
        access_level_description: 'Some user',
        access_level: null,
        group_id: null,
        required_approvals: 1,
      },
    ],
  },
];

const DEFAULT_PROJECT_ID = '8';
const DEFAULT_ACCESS_LEVELS_DATA = [
  {
    id: 40,
    text: 'Maintainers',
    before_divider: true,
  },
  {
    id: 30,
    text: 'Developers + Maintainers',
    before_divider: true,
  },
];

Vue.use(Vuex);

describe('ee/protected_environments/edit_protected_environments_list.vue', () => {
  let store;
  let wrapper;
  let mock;

  const createComponent = async () => {
    store = createStore({ projectId: DEFAULT_PROJECT_ID });

    wrapper = mountExtended(EditProtectedEnvironmentsList, {
      store,
      provide: {
        accessLevelsData: DEFAULT_ACCESS_LEVELS_DATA,
      },
    });

    await waitForPromises();
  };

  const findDeployerDeleteButton = () =>
    wrapper.findByTitle(s__('ProtectedEnvironments|Delete deployer rule'));
  const findApproverDeleteButton = () =>
    wrapper.findByTitle(s__('ProtectedEnvironments|Delete approver rule'));
  const findApproverEditButton = (w = wrapper) =>
    w.findByRole('button', { name: s__('ProtectedEnvironments|Edit') });
  const findApproverSaveButton = () =>
    wrapper.findByRole('button', { name: s__('ProtectedEnvironments|Save') });
  const findApprovalsInput = () =>
    wrapper.findByRole('textbox', { name: s__('ProtectedEnvironments|Required approval count') });

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = { api_version: 'v4' };
    mock
      .onGet('/api/v4/projects/8/protected_environments/')
      .reply(HTTP_STATUS_OK, DEFAULT_ENVIRONMENTS);
    mock
      .onGet('/api/v4/groups/1/members/all')
      .reply(HTTP_STATUS_OK, [{ name: 'root', avatar_url: '/avatar.png' }]);
    mock
      .onGet('/api/v4/users/1')
      .reply(HTTP_STATUS_OK, { name: 'root', avatar_url: '/avatar.png' });
    mock.onGet('/api/v4/projects/8/members').reply(HTTP_STATUS_OK, [
      {
        name: 'root',
        access_level: MAINTAINER_ACCESS_LEVEL.toString(),
        avatar_url: '/avatar.png',
      },
    ]);
  });

  afterEach(() => {
    mock.restore();
    mock.resetHistory();
  });

  it('shows a header counting the number of protected environments', async () => {
    await createComponent();

    expect(
      wrapper
        .findByRole('heading', {
          name: sprintf(
            s__(
              'ProtectedEnvironments|List of protected environments (%{protectedEnvironmentsCount})',
            ),
            { protectedEnvironmentsCount: 1 },
          ),
        })
        .exists(),
    ).toBe(true);
  });

  it('shows a header for the protected environment', async () => {
    await createComponent();

    expect(wrapper.findByRole('button', { name: 'staging' }).exists()).toBe(true);
  });

  it('shows member avatars in each row', async () => {
    await createComponent();

    const avatars = wrapper.findAllComponents(GlAvatar).wrappers;

    expect(avatars).toHaveLength(6);
    avatars.forEach((avatar) => expect(avatar.props('src')).toBe('/avatar.png'));
  });

  it('shows the description of the rule', async () => {
    const [
      { deploy_access_levels: deployAccessLevels, approval_rules: approvalRules },
    ] = DEFAULT_ENVIRONMENTS;

    const ruleDescriptions = [
      ...deployAccessLevels.map((d) => d.access_level_description),
      ...approvalRules.map((a) => a.access_level_description),
    ];

    await createComponent();

    const descriptions = wrapper.findAllByTestId('rule-description').wrappers;

    descriptions.forEach((description, i) => {
      expect(description.text()).toBe(ruleDescriptions[i]);
    });
  });

  describe('add deployer rule', () => {
    let environment;
    let dropdown;
    let modal;

    beforeEach(async () => {
      [environment] = DEFAULT_ENVIRONMENTS;

      await createComponent();

      wrapper
        .findComponent(EditProtectedEnvironmentRulesCard)
        .vm.$emit('addRule', { environment, ruleKey: DEPLOYER_RULE_KEY });

      await nextTick();

      dropdown = wrapper.findComponent(AccessDropdown);
      modal = wrapper.findComponent(AddRuleModal);
    });

    it('titles the modal appropriately', () => {
      expect(modal.props('title')).toBe(s__('ProtectedEnvironments|Create deployment rule'));
    });

    it('puts the access level dropdown into the modal form', () => {
      expect(dropdown.exists()).toBe(true);
    });

    it('sends new rules to be added', async () => {
      mock.onPut().reply(HTTP_STATUS_OK);

      const rule = [{ user_id: 5 }];
      dropdown.vm.$emit('hidden', rule);

      modal.vm.$emit('saveRule');

      await waitForPromises();

      expect(mock.history.put).toHaveLength(1);

      const [{ data }] = mock.history.put;
      expect(JSON.parse(data)).toMatchObject({ ...environment, deploy_access_levels: rule });
    });
  });

  describe('deployer delete rule', () => {
    it('sends the deleted rule with _destroy set', async () => {
      const [environment] = DEFAULT_ENVIRONMENTS;

      await createComponent();

      wrapper.findComponent(GlButton).vm.$emit('click');

      const button = findDeployerDeleteButton();

      mock.onPut().reply(HTTP_STATUS_OK);

      const destroyedRule = {
        access_level: DEVELOPER_ACCESS_LEVEL,
        access_level_description: 'Deployers + Maintainers',
        _destroy: true,
      };

      button.trigger('click');

      await waitForPromises();

      expect(mock.history.put).toHaveLength(1);

      const [{ data }] = mock.history.put;
      expect(JSON.parse(data)).toMatchObject({
        name: environment.name,
        deploy_access_levels: [destroyedRule],
      });
    });

    it('hides the button if there is only one rule', async () => {
      const [environment] = DEFAULT_ENVIRONMENTS;
      const [rule] = environment.deploy_access_levels;
      mock.onGet('/api/v4/projects/8/protected_environments/').reply(HTTP_STATUS_OK, [
        {
          ...environment,
          deploy_access_levels: [rule],
        },
      ]);

      await createComponent();

      wrapper.findComponent(GlButton).vm.$emit('click');

      const button = findDeployerDeleteButton();

      expect(button.exists()).toBe(false);
    });
  });

  describe('add approval rule', () => {
    let environment;
    let addApprover;
    let modal;

    beforeEach(async () => {
      [environment] = DEFAULT_ENVIRONMENTS;

      await createComponent();

      wrapper
        .findComponent(EditProtectedEnvironmentRulesCard)
        .vm.$emit('addRule', { environment, ruleKey: APPROVER_RULE_KEY });

      await nextTick();

      addApprover = wrapper.findComponent(AddApprovers);
      modal = wrapper.findComponent(AddRuleModal);
    });

    it('titles the modal appropriately', () => {
      expect(modal.props('title')).toBe(s__('ProtectedEnvironments|Create approval rule'));
    });

    it('puts the access level dropdown into the modal form', () => {
      expect(addApprover.exists()).toBe(true);
    });

    it('sends new rules to be added', async () => {
      mock.onPut().reply(HTTP_STATUS_OK);

      const rule = [{ user_id: 5, required_approvals: 3 }];
      addApprover.vm.$emit('change', rule);

      modal.vm.$emit('saveRule');

      await waitForPromises();

      expect(mock.history.put).toHaveLength(1);

      const [{ data }] = mock.history.put;
      expect(JSON.parse(data)).toMatchObject({ ...environment, approval_rules: rule });
    });
  });

  describe('approver delete rule', () => {
    it('sends the deleted rule with _destroy set', async () => {
      const [environment] = DEFAULT_ENVIRONMENTS;

      await createComponent();

      wrapper.findComponent(GlButton).vm.$emit('click');

      const button = findApproverDeleteButton();

      mock.onPut().reply(HTTP_STATUS_OK);

      const destroyedRule = {
        access_level: DEVELOPER_ACCESS_LEVEL,
        access_level_description: 'Deployers + Maintainers',
        _destroy: true,
      };

      button.trigger('click');

      await waitForPromises();

      expect(mock.history.put).toHaveLength(1);

      const [{ data }] = mock.history.put;
      expect(JSON.parse(data)).toMatchObject({
        name: environment.name,
        approval_rules: [destroyedRule],
      });
    });
  });

  describe('approver edit rule', () => {
    let environment;

    beforeEach(async () => {
      [environment] = DEFAULT_ENVIRONMENTS;
      await createComponent();

      wrapper.findComponent(GlButton).vm.$emit('click');

      await nextTick();
    });

    it('allows editing of an approval rule', async () => {
      const [rule] = environment.approval_rules;
      const value = '2';

      mock.onPut().reply(HTTP_STATUS_OK);

      const button = findApproverEditButton();

      await button.trigger('click');

      const input = findApprovalsInput();

      expect(input.exists()).toBe(true);

      await input.setValue(value);

      findApproverSaveButton().trigger('click');

      await waitForPromises();

      expect(mock.history.put.length).toBe(1);
      const [{ data }] = mock.history.put;
      expect(JSON.parse(data)).toMatchObject({
        name: environment.name,
        approval_rules: [
          {
            id: rule.id,
            access_level: rule.access_level,
            access_level_description: rule.access_level_description,
            required_approvals: value,
          },
        ],
      });
    });

    it('hides the edit button for user rules', () => {
      const { id } = environment.approval_rules.find(({ user_id: userId }) => userId);
      const row = wrapper.findByTestId(`approval_rules-${id}`);
      const button = findApproverEditButton(extendedWrapper(row));

      expect(button.exists()).toBe(false);
    });
  });

  describe('unprotect environment', () => {
    it('unprotects an environment when emitted', async () => {
      const [environment] = DEFAULT_ENVIRONMENTS;

      mock.onDelete().reply(HTTP_STATUS_OK);

      await createComponent();

      wrapper.findComponent(ProtectedEnvironments).vm.$emit('unprotect', environment);
      await waitForPromises();

      expect(mock.history.delete).toHaveLength(1);

      const [{ url }] = mock.history.delete;
      expect(url).toBe(`/api/v4/projects/8/protected_environments/${environment.name}`);
    });
  });
});
