import { nextTick } from 'vue';
import mockTimezones from 'test_fixtures/timezones/full.json';
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

  const initRule = {
    type: SCAN_EXECUTION_PIPELINE_RULE,
    branches: [],
  };

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = mountExtended(PolicyRuleBuilder, {
      propsData: {
        initRule,
        ...propsData,
      },
      provide: {
        ...provide,
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
      provide: {
        timezones: mockTimezones,
      },
    });

    findScheduleRuleComponent().vm.$emit('select-rule', SCAN_EXECUTION_SCHEDULE_RULE);
    await nextTick();

    const [payload] = wrapper.emitted().changed[0];

    expect(payload).toEqual(RULE_KEY_MAP[SCAN_EXECUTION_SCHEDULE_RULE]());
  });
});
