import { nextTick } from 'vue';
import { GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BaseRuleComponent from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/base_rule_component.vue';
import {
  SCAN_EXECUTION_SCHEDULE_RULE,
  SCAN_EXECUTION_RULES_LABELS,
} from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/constants';

describe('BaseRuleComponent', () => {
  let wrapper;
  const ruleLabel = s__('ScanExecutionPolicy|if');
  const initRule = {
    type: SCAN_EXECUTION_SCHEDULE_RULE,
    branches: [],
  };

  const createComponent = (options = {}) => {
    wrapper = mountExtended(BaseRuleComponent, {
      propsData: {
        initRule,
        ruleLabel,
        ...options,
      },
    });
  };

  const findRuleTypeDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findRuleTypeDropDown = () => wrapper.findByTestId('rule-component-type');
  const findRuleBranchesInput = () => wrapper.findByTestId('rule-branches');
  const findScheduleRuleLabel = () => wrapper.findByTestId('rule-component-label');

  beforeEach(() => {
    createComponent();
  });

  it('should render pipeline rule by default', () => {
    expect(findScheduleRuleLabel().text()).toEqual(ruleLabel);
    expect(findRuleTypeDropDown().props('text')).toEqual(
      capitalizeFirstCharacter(SCAN_EXECUTION_RULES_LABELS.pipeline),
    );
  });

  it('should select pipeline rule', async () => {
    findRuleTypeDropdownItems().at(1).vm.$emit('click');
    await nextTick();
    const [eventPayload] = wrapper.emitted()['select-rule'];

    expect(eventPayload[0]).toEqual(SCAN_EXECUTION_RULES_LABELS.schedule.toLowerCase());
  });

  it('should select list of branches', async () => {
    const branches = 'main,branch1,branch2';

    findRuleBranchesInput().vm.$emit('input', branches);
    await nextTick();
    const [eventPayload] = wrapper.emitted().changed;

    expect(eventPayload[0]).toEqual({
      type: SCAN_EXECUTION_SCHEDULE_RULE,
      branches: branches.split(','),
    });
  });
});
