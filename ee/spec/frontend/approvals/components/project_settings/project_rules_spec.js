import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import RuleInput from 'ee/approvals/components/mr_edit/rule_input.vue';
import ProjectRules from 'ee/approvals/components/project_settings/project_rules.vue';
import RuleName from 'ee/approvals/components/rule_name.vue';
import Rules from 'ee/approvals/components/rules.vue';
import UnconfiguredSecurityRules from 'ee/approvals/components/security_configuration/unconfigured_security_rules.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { createProjectRules } from '../../mocks';

const TEST_RULES = createProjectRules();

Vue.use(Vuex);

const findCell = (tr, name) => tr.find(`td.js-${name}`);

const getRowData = (tr) => {
  const name = findCell(tr, 'name');
  const members = findCell(tr, 'members');
  const approvalsRequired = findCell(tr, 'approvals-required');
  return {
    name: name.text(),
    approvers: members.findComponent(UserAvatarList).props('items'),
    approvalsRequired: approvalsRequired.findComponent(RuleInput).props('rule').approvalsRequired,
  };
};

describe('Approvals ProjectRules', () => {
  let wrapper;
  let store;

  const factory = (props = {}, options = {}) => {
    wrapper = mount(ProjectRules, {
      propsData: props,
      store: new Vuex.Store(store),
      ...options,
    });
  };

  beforeEach(() => {
    store = createStoreOptions({ approvals: projectSettingsModule() });
    store.modules.approvals.state.rules = TEST_RULES;
  });

  describe('when allow multiple rules', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
    });

    it('renders row for each rule', () => {
      factory();

      const rows = wrapper
        .findComponent(Rules)
        .findAll('tbody tr')
        .filter((tr, index) => index !== 0);
      const data = rows.wrappers.map(getRowData);

      expect(data).toEqual(
        TEST_RULES.filter((rule, index) => index !== 0).map((rule) => ({
          name: rule.name,
          approvers: rule.eligibleApprovers,
          approvalsRequired: rule.approvalsRequired,
        })),
      );

      expect(wrapper.findComponent(Rules).findAllComponents(RuleName).length).toBe(rows.length);
    });

    it('should always have any_approver rule', () => {
      factory();
      const hasAnyApproverRule = store.modules.approvals.state.rules.some(
        (rule) => rule.ruleType === 'any_approver',
      );

      expect(hasAnyApproverRule).toBe(true);
    });
  });

  describe('when only allow single rule', () => {
    let rule;
    let row;

    beforeEach(() => {
      [rule] = TEST_RULES;
      store.modules.approvals.state.rules = [rule];

      factory();

      row = wrapper.findComponent(Rules).find('tbody tr');
    });

    it('does not render name', () => {
      expect(findCell(row, 'name').exists()).toBe(false);
      expect(wrapper.findComponent(Rules).findComponent(RuleName).exists()).toBe(false);
    });

    it('should only display 1 rule', () => {
      expect(store.modules.approvals.state.rules.length).toBe(1);
    });
  });

  describe('approval suggestions', () => {
    beforeEach(() => {
      const rules = createProjectRules();
      rules[0].name = 'Coverage-Check';
      store.modules.approvals.state.rules = rules;
      store.state.settings.allowMultiRule = true;

      factory();
    });

    it(`should render the unconfigured-security-rules component`, () => {
      expect(wrapper.findComponent(UnconfiguredSecurityRules).exists()).toBe(true);
    });
  });
});
