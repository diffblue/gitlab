import { GlCollapsibleListbox } from '@gitlab/ui';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import StatusFilter from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/status_filter.vue';
import RuleMultiSelect from 'ee/security_orchestration/components/policy_editor/rule_multi_select.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  APPROVAL_VULNERABILITY_STATES,
} from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/constants';

describe('StatusFilter', () => {
  let wrapper;

  const testStateNew1 = 'new_needs_triage';
  const testStateNew2 = 'new_detected';
  const testStatePreviouslyDetected = 'detected';

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StatusFilter, {
      propsData: {
        ...props,
      },
      stubs: {
        SectionLayout,
        GlCollapsibleListbox,
        RuleMultiSelect,
      },
    });
  };

  const findSectionLayout = () => wrapper.findComponent(SectionLayout);
  const findListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findPolicyRuleMultiSelect = () => wrapper.findComponent(RuleMultiSelect);
  const findAllSelectedItem = () => wrapper.findByTestId('listbox-select-all-button');

  it('renders both dropdowns', () => {
    createComponent();

    expect(findListBox().exists()).toBe(true);
    expect(findPolicyRuleMultiSelect().exists()).toBe(true);
  });

  describe('new filters', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders initial items for the provided filter', () => {
      expect(Object.keys(findPolicyRuleMultiSelect().props('items'))).toEqual(
        Object.keys(APPROVAL_VULNERABILITY_STATES[NEWLY_DETECTED]),
      );
    });

    it('should select states', () => {
      findPolicyRuleMultiSelect().vm.$emit('input', [testStateNew1]);
      findPolicyRuleMultiSelect().vm.$emit('input', [testStateNew2]);

      expect(wrapper.emitted('input')).toEqual([[[testStateNew1]], [[testStateNew2]]]);
    });

    it('should select different filter and emit input event', async () => {
      await findListBox().vm.$emit('select', PREVIOUSLY_EXISTING);

      expect(wrapper.emitted('change-group')).toEqual([[PREVIOUSLY_EXISTING]]);
    });

    it('should select all statuses', () => {
      findAllSelectedItem().vm.$emit('click');

      expect(wrapper.emitted('input')).toEqual([[['new_needs_triage', 'new_dismissed']]]);
    });

    it('disregard previously selected values when changing filter', async () => {
      await findPolicyRuleMultiSelect().vm.$emit('input', [testStateNew1]);
      await findListBox().vm.$emit('select', PREVIOUSLY_EXISTING);
      await findPolicyRuleMultiSelect().vm.$emit('input', [testStatePreviouslyDetected]);

      expect(wrapper.emitted('change-group')).toEqual([[PREVIOUSLY_EXISTING]]);
      expect(wrapper.emitted('input')).toEqual([
        [[testStateNew1]],
        [[testStatePreviouslyDetected]],
      ]);
    });
  });

  describe('existing filters', () => {
    it('should transform "newly_detected" state to "new_dismissed" and "new_needs_triage"', () => {
      createComponent({ selected: [NEWLY_DETECTED] });

      expect(findListBox().props('selected')).toEqual(NEWLY_DETECTED);
      expect(findPolicyRuleMultiSelect().props('value')).toEqual([
        'new_needs_triage',
        'new_dismissed',
      ]);
    });

    it.each`
      filter                 | selected
      ${NEWLY_DETECTED}      | ${[testStateNew1]}
      ${PREVIOUSLY_EXISTING} | ${[testStatePreviouslyDetected]}
    `('should select existing values for filter $filter', ({ filter, selected }) => {
      createComponent({ selected, filter });

      expect(findListBox().props('selected')).toEqual(filter);
      expect(findPolicyRuleMultiSelect().props('value')).toEqual(selected);
    });
  });

  describe('remove', () => {
    it('should remove filter when only one is present', async () => {
      createComponent({ selected: [testStateNew1] });

      await findSectionLayout().vm.$emit('remove');

      expect(wrapper.emitted('remove')).toHaveLength(1);
    });
  });
});
