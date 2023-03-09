import { GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import AddEscalationPolicyForm, {
  i18n,
} from 'ee/escalation_policies/components/add_edit_escalation_policy_form.vue';
import EscalationRule from 'ee/escalation_policies/components/escalation_rule.vue';
import { DEFAULT_ESCALATION_RULE, MAX_RULES_LENGTH } from 'ee/escalation_policies/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import mockPolicies from './mocks/mockPolicies.json';

describe('AddEscalationPolicyForm', () => {
  let wrapper;
  const projectPath = 'group/project';

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(AddEscalationPolicyForm, {
      propsData: {
        form: {
          name: mockPolicies[1].name,
          description: mockPolicies[1].description,
          rules: [],
        },
        validationState: {
          name: true,
          rules: [],
        },
        ...props,
      },
      provide: {
        projectPath,
      },
      mocks: {
        $apollo: {
          queries: { schedules: { loading: false } },
        },
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findRules = () => wrapper.findAllComponents(EscalationRule);
  const findAddRuleLink = () => wrapper.findComponent(GlLink);
  const findMaxRulesText = () => wrapper.findByTestId('max-rules-text');

  describe('Escalation rules', () => {
    it('should render one default rule when rules were not provided', () => {
      expect(findRules()).toHaveLength(1);
    });

    it('should render all the rules if they were provided', async () => {
      createComponent({ props: { form: { rules: mockPolicies[1].rules } } });
      await nextTick();
      expect(findRules()).toHaveLength(mockPolicies[1].rules.length);
    });

    it('should contain a link to add escalation rules', () => {
      const link = findAddRuleLink();
      expect(link.exists()).toBe(true);
      expect(link.text()).toMatchInterpolatedText(i18n.addRule);
    });

    it('should show max rules message when at max rules capacity', async () => {
      // Create 10 rules
      const rules = Array(MAX_RULES_LENGTH).fill(mockPolicies[1].rules[0]);
      createComponent({ props: { form: { rules } } });

      await nextTick();
      const link = findAddRuleLink();
      expect(findRules()).toHaveLength(MAX_RULES_LENGTH);
      expect(link.exists()).toBe(false);

      const maxRules = findMaxRulesText();
      expect(maxRules.exists()).toBe(true);
      expect(maxRules.text()).toMatchInterpolatedText(i18n.maxRules);
    });

    it('should add an empty rule to the rules list on click', async () => {
      findAddRuleLink().vm.$emit('click');
      await nextTick();
      const rules = findRules();
      expect(rules.length).toBe(2);
      expect(rules.at(1).props('rule')).toMatchObject(DEFAULT_ESCALATION_RULE);
    });

    it('should NOT emit updates when rule is added', async () => {
      findAddRuleLink().vm.$emit('click');
      await nextTick();
      expect(wrapper.emitted('update-escalation-policy-form')).toBeUndefined();
    });

    it('on rule update emitted should update rules array and emit updates up', async () => {
      const ruleBeforeUpdate = {
        status: 'RESOLVED',
        elapsedTimeMinutes: 3,
        username: 'user',
      };

      createComponent({ props: { form: { rules: [ruleBeforeUpdate] } } });
      await nextTick();
      const updatedRule = {
        status: 'TRIGGERED',
        elapsedTimeMinutes: 3,
        oncallScheduleIid: 2,
      };
      findRules().at(0).vm.$emit('update-escalation-rule', { index: 0, rule: updatedRule });
      const emittedValue = wrapper.emitted('update-escalation-policy-form')[0];
      expect(emittedValue).toEqual([
        { field: 'rules', value: [expect.objectContaining(updatedRule)] },
      ]);
      expect(emittedValue).not.toEqual([
        { field: 'rules', value: [expect.objectContaining(ruleBeforeUpdate)] },
      ]);
    });

    it('on rule removal emitted should update rules array and emit updates up', () => {
      findRules().at(0).vm.$emit('remove-escalation-rule', 0);
      expect(wrapper.emitted('update-escalation-policy-form')[0]).toEqual([
        { field: 'rules', value: [] },
      ]);
    });
  });
});
