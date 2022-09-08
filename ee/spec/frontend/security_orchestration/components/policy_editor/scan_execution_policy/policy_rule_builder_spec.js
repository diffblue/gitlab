import { nextTick } from 'vue';
import { __ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/policy_rule_builder.vue';
import BaseRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/base_rule_component.vue';
import ScheduleRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/schedule_rule_component.vue';
import { RULE_KEY_MAP } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib/rules';
import {
  SCAN_EXECUTION_PIPELINE_RULE,
  SCAN_EXECUTION_SCHEDULE_RULE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import { CRON_DEFAULT_TIME } from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';

describe('PolicyRuleBuilder', () => {
  let wrapper;
  const ruleIfLabel = __('if');
  const ruleOrLabel = __('or');

  const initRule = {
    type: SCAN_EXECUTION_PIPELINE_RULE,
    branches: [],
  };

  const createComponent = (options = {}) => {
    wrapper = mountExtended(PolicyRuleBuilder, {
      propsData: {
        initRule,
        ...options,
      },
    });
  };

  const findPipelineRuleComponentLabel = () => wrapper.findByTestId('rule-component-label');
  const findBaseRuleComponent = () => wrapper.findComponent(BaseRuleComponent);
  const findScheduleRuleComponent = () => wrapper.findComponent(ScheduleRuleComponent);

  it.each`
    ruleIndex | expectedResult
    ${0}      | ${ruleIfLabel}
    ${1}      | ${ruleOrLabel}
    ${2}      | ${ruleOrLabel}
  `('should display correct label based on rule order', ({ ruleIndex, expectedResult }) => {
    createComponent({ ruleIndex });

    expect(findPipelineRuleComponentLabel().text()).toContain(expectedResult);
    expect(findBaseRuleComponent().props('ruleLabel')).toEqual(expectedResult);
  });

  it.each`
    type                            | expectedRule
    ${SCAN_EXECUTION_SCHEDULE_RULE} | ${RULE_KEY_MAP[SCAN_EXECUTION_SCHEDULE_RULE]}
    ${SCAN_EXECUTION_PIPELINE_RULE} | ${RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE]}
  `('should change rules', async ({ type, expectedRule }) => {
    createComponent();

    findBaseRuleComponent().vm.$emit('select-rule', type);

    await nextTick();

    expect(wrapper.emitted()).toEqual({
      changed: [[expectedRule()]],
    });
  });

  it('should select correct schedule rule', async () => {
    createComponent({
      initRule: {
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        branches: [],
        cadence: CRON_DEFAULT_TIME,
      },
    });

    findScheduleRuleComponent().vm.$emit('select-rule', SCAN_EXECUTION_SCHEDULE_RULE);
    await nextTick();

    const [payload] = wrapper.emitted().changed[0];

    expect(payload).toEqual(RULE_KEY_MAP[SCAN_EXECUTION_SCHEDULE_RULE]());
  });
});
