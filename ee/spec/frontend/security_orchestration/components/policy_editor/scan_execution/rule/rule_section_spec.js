import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PolicyRuleBuilder from 'ee/security_orchestration/components/policy_editor/scan_execution/rule/rule_section.vue';
import BaseRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution/rule/base_rule_component.vue';
import ScheduleRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution/rule/schedule_rule_component.vue';
import { RULE_KEY_MAP } from 'ee/security_orchestration/components/policy_editor/scan_execution/lib/rules';
import {
  SCAN_EXECUTION_PIPELINE_RULE,
  SCAN_EXECUTION_SCHEDULE_RULE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution/constants';
import { CRON_DEFAULT_TIME } from 'ee/security_orchestration/components/policy_editor/scan_execution/lib';

describe('PolicyRuleBuilder', () => {
  let wrapper;

  const initRule = {
    type: SCAN_EXECUTION_PIPELINE_RULE,
    branches: [],
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(PolicyRuleBuilder, {
      propsData: {
        initRule,
        ...propsData,
      },
    });
  };

  const findBaseRuleComponent = () => wrapper.findComponent(BaseRuleComponent);
  const findScheduleRuleComponent = () => wrapper.findComponent(ScheduleRuleComponent);
  const findRuleSeperator = () => wrapper.findByTestId('rule-separator');

  it.each`
    ruleIndex | expectedResult
    ${0}      | ${false}
    ${1}      | ${true}
  `('displays correct label based on rule order', ({ ruleIndex, expectedResult }) => {
    createComponent({
      propsData: { ruleIndex },
    });

    expect(findRuleSeperator().exists()).toBe(expectedResult);
  });

  it.each`
    type                            | expectedRule
    ${SCAN_EXECUTION_SCHEDULE_RULE} | ${RULE_KEY_MAP[SCAN_EXECUTION_SCHEDULE_RULE]}
    ${SCAN_EXECUTION_PIPELINE_RULE} | ${RULE_KEY_MAP[SCAN_EXECUTION_PIPELINE_RULE]}
  `('changes rules', async ({ type, expectedRule }) => {
    createComponent();

    findBaseRuleComponent().vm.$emit('select-rule', type);

    await nextTick();

    expect(wrapper.emitted()).toEqual({
      changed: [[expectedRule()]],
    });
  });

  it('selects correct schedule rule', async () => {
    createComponent({
      propsData: {
        initRule: {
          type: SCAN_EXECUTION_SCHEDULE_RULE,
          branches: [],
          cadence: CRON_DEFAULT_TIME,
        },
      },
    });

    findScheduleRuleComponent().vm.$emit('select-rule', SCAN_EXECUTION_SCHEDULE_RULE);
    await nextTick();

    const [payload] = wrapper.emitted().changed[0];

    expect(payload).toEqual(RULE_KEY_MAP[SCAN_EXECUTION_SCHEDULE_RULE]());
  });
});
