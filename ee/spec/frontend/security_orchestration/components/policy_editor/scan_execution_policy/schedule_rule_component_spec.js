import { GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/base_rule_component.vue';
import ScheduleRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/schedule_rule_component.vue';
import {
  DEFAULT_AGENT_NAME,
  SCAN_EXECUTION_SCHEDULE_RULE,
  SCAN_EXECUTION_RULE_SCOPE_AGENT_KEY,
  SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY,
  SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { CRON_DEFAULT_TIME } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';

describe('ScheduleRuleComponent', () => {
  let wrapper;
  const ruleLabel = s__('ScanExecutionPolicy|if');
  const initRule = {
    type: SCAN_EXECUTION_SCHEDULE_RULE,
    branches: [],
    cadence: CRON_DEFAULT_TIME,
  };

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(ScheduleRuleComponent, {
      propsData: {
        initRule,
        ruleLabel,
        ...options,
      },
      stubs: {
        BaseRuleComponent,
        GlSprintf,
      },
    });
  };

  const findScheduleRuleScopeDropDown = () => wrapper.findByTestId('rule-component-scope');
  const findScheduleRuleTypeDropDown = () => wrapper.findByTestId('rule-component-type');
  const findScheduleRulePeriodDropDown = () => wrapper.findByTestId('rule-component-period');
  const findScheduleRuleAgentInput = () => wrapper.findByTestId('pipeline-rule-agent');
  const findScheduleRuleNamespacesInput = () => wrapper.findByTestId('pipeline-rule-namespaces');
  const findScheduleRuleTimeDropDown = () => wrapper.findByTestId('rule-component-time');
  const findScheduleRuleDayDropDown = () => wrapper.findByTestId('rule-component-day');

  describe('select branch scope', () => {
    beforeEach(() => {
      createComponent();
    });
  });

  describe('select agent scope and namespaces', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should set default agent name if no name was provided', async () => {
      const agentName = 'other-then-default';
      findScheduleRuleScopeDropDown().vm.$emit('select', SCAN_EXECUTION_RULE_SCOPE_AGENT_KEY);
      await nextTick();

      findScheduleRuleAgentInput().vm.$emit('update', agentName);
      await nextTick();
      findScheduleRuleAgentInput().vm.$emit('update', '');
      await nextTick();

      const [eventPayload] = wrapper.emitted().changed[3];

      expect(eventPayload).toMatchObject({
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        agents: {
          [DEFAULT_AGENT_NAME]: {
            namespaces: [],
          },
        },
        cadence: CRON_DEFAULT_TIME,
      });
    });

    it('should select agent and list of name spaces', async () => {
      const agent = 'cube-agent';
      const namespaces = 'namespace1,namespace2,namespace3';

      findScheduleRuleScopeDropDown().vm.$emit('select', SCAN_EXECUTION_RULE_SCOPE_AGENT_KEY);
      await nextTick();

      findScheduleRuleAgentInput().vm.$emit('update', agent);
      findScheduleRuleNamespacesInput().vm.$emit('update', namespaces);

      const [eventPayload] = wrapper.emitted().changed[3];

      expect(eventPayload).toMatchObject({
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        agents: {
          [agent]: {
            namespaces: ['namespace1', 'namespace2', 'namespace3'],
          },
        },
        cadence: CRON_DEFAULT_TIME,
      });
    });
  });

  describe('select correct time', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should select correct time', () => {
      findScheduleRuleTimeDropDown().vm.$emit('select', '1');

      const [eventPayload] = wrapper.emitted().changed[0];
      expect(eventPayload).toEqual({
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        branches: [],
        cadence: '0 1 * * *',
      });
    });

    it('should select correct time and day', async () => {
      findScheduleRulePeriodDropDown().vm.$emit('select', SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY);
      await nextTick();

      findScheduleRuleTimeDropDown().vm.$emit('select', '2');
      findScheduleRuleDayDropDown().vm.$emit('select', '2');

      await nextTick();

      const [eventPayload] = wrapper.emitted().changed[2];
      expect(eventPayload).toEqual({
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        branches: [],
        cadence: '0 2 * * 2',
      });
    });
  });

  describe('parse existing rules', () => {
    it('should parse existing rules correctly', () => {
      createComponent({
        initRule: {
          type: SCAN_EXECUTION_SCHEDULE_RULE,
          cadence: '0 9 * * 4',
          branches: ['branch1,branch2'],
        },
      });

      expect(findScheduleRuleTypeDropDown().props('selected')).toBe(initRule.type);

      expect(findScheduleRuleScopeDropDown().props('selected')).toBe(
        SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY,
      );

      expect(findScheduleRuleTimeDropDown().props('selected')).toBe('9');
      expect(findScheduleRuleDayDropDown().props('selected')).toBe('4');
      expect(findScheduleRulePeriodDropDown().props('selected')).toBe(
        SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY,
      );
    });
  });
});
