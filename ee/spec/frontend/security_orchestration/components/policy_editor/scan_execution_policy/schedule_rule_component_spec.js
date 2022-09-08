import { GlDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { s__ } from '~/locale';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import ScheduleRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/schedule_rule_component.vue';
import {
  SCAN_EXECUTION_SCHEDULE_RULE,
  SCAN_EXECUTION_RULE_SCOPE_TYPE,
  SCAN_EXECUTION_RULE_PERIOD_TYPE,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';
import {
  CRON_DEFAULT_TIME,
  DAYS,
  HOUR_MINUTE_LIST,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/lib';

describe('ScheduleRuleComponent', () => {
  let wrapper;
  const ruleLabel = s__('ScanExecutionPolicy|if');
  const initRule = {
    type: SCAN_EXECUTION_SCHEDULE_RULE,
    branches: [],
    cadence: CRON_DEFAULT_TIME,
  };

  const createComponent = (options = {}) => {
    wrapper = mountExtended(ScheduleRuleComponent, {
      propsData: {
        initRule,
        ruleLabel,
        ...options,
      },
      stubs: { GlDropdownItem: true },
    });
  };

  const findScheduleRuleScopeDropDown = () => wrapper.findByTestId('rule-component-scope');
  const findScheduleRuleTypeDropDown = () => wrapper.findByTestId('rule-component-type');
  const findScheduleRulePeriodDropDown = () => wrapper.findByTestId('rule-component-period');
  const findScheduleRulePeriodWeeklyItem = () =>
    findScheduleRulePeriodDropDown().findAllComponents(GlDropdownItem).at(1);
  const findScheduleRuleTimeDropDown = () => wrapper.findByTestId('rule-component-time');
  const findScheduleRuleDayDropDown = () => wrapper.findByTestId('rule-component-day');
  const findScheduleRuleDayDropDownItem = () =>
    findScheduleRuleDayDropDown().findAllComponents(GlDropdownItem);

  describe('select branch scope', () => {
    beforeEach(() => {
      createComponent();
    });
  });

  describe('select correct time', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should select correct time', () => {
      findScheduleRuleTimeDropDown().findAllComponents(GlDropdownItem).at(1).vm.$emit('click');

      const [eventPayload] = wrapper.emitted().changed[0];
      expect(eventPayload).toEqual({
        type: SCAN_EXECUTION_SCHEDULE_RULE,
        branches: [],
        cadence: '0 1 * * *',
      });
    });

    it('should select correct time and day', async () => {
      findScheduleRulePeriodWeeklyItem().vm.$emit('click');
      await nextTick();

      findScheduleRuleTimeDropDown().findAllComponents(GlDropdownItem).at(2).vm.$emit('click');
      findScheduleRuleDayDropDownItem().at(2).vm.$emit('click');

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
    it('should parse existing rules correctly', async () => {
      createComponent({
        initRule: {
          type: SCAN_EXECUTION_SCHEDULE_RULE,
          cadence: '0 9 * * 4',
          branches: ['branch1,branch2'],
        },
      });

      expect(findScheduleRuleTypeDropDown().props('text')).toEqual(
        capitalizeFirstCharacter(initRule.type),
      );

      expect(findScheduleRuleScopeDropDown().props('text')).toEqual(
        SCAN_EXECUTION_RULE_SCOPE_TYPE.branch,
      );

      expect(findScheduleRuleTimeDropDown().props('text')).toEqual(HOUR_MINUTE_LIST[9]);
      expect(findScheduleRuleDayDropDown().props('text')).toEqual(DAYS[4]);
      expect(findScheduleRulePeriodDropDown().props('text')).toEqual(
        SCAN_EXECUTION_RULE_PERIOD_TYPE.weekly,
      );
    });
  });
});
