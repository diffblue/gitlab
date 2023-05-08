import StatusFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/status_filter.vue';
import SeverityFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/severity_filter.vue';
import BaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/scan_result_policy/base_layout/base_layout_component.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { APPROVAL_VULNERABILITY_STATE_GROUPS } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';

describe('FilterSpec', () => {
  let wrapper;
  let testKey1;
  let testKey2;

  const testCases = [
    {
      component: SeverityFilter,
      filterOptions: SEVERITY_LEVELS,
    },
    {
      component: StatusFilter,
      filterOptions: APPROVAL_VULNERABILITY_STATE_GROUPS,
    },
  ];

  const createComponent = ({ component = SeverityFilter, props = {} } = {}) => {
    wrapper = shallowMountExtended(component, {
      propsData: {
        ...props,
      },
      stubs: {
        BaseLayoutComponent,
      },
    });
  };

  const findBaseLayoutComponent = () => wrapper.findComponent(BaseLayoutComponent);
  const findPolicyRuleMultiSelect = () => wrapper.findComponent(PolicyRuleMultiSelect);
  const findRemoveButton = () => wrapper.findByTestId('remove-rule');

  describe.each(testCases)('new filters', ({ component, filterOptions }) => {
    beforeEach(() => {
      createComponent({ component });
      [testKey1, testKey2] = Object.keys(filterOptions);
    });

    it('should render filters dropdown', () => {
      expect(findPolicyRuleMultiSelect().exists()).toBe(true);
    });

    it('should select filters', () => {
      findPolicyRuleMultiSelect().vm.$emit('input', [testKey1]);
      findPolicyRuleMultiSelect().vm.$emit('input', [testKey2]);

      expect(wrapper.emitted('input')).toEqual([[[testKey1]], [[testKey2]]]);
    });

    describe('existing filters', () => {
      beforeEach(() => {
        createComponent({
          props: { selected: [testKey1, testKey2] },
        });
      });

      it('should select existing filters', () => {
        expect(findPolicyRuleMultiSelect().props('value')).toEqual([testKey1, testKey2]);
      });

      it('should remove filter', () => {
        findBaseLayoutComponent().vm.$emit('remove');

        expect(wrapper.emitted('remove')).toHaveLength(1);
      });
    });

    describe('remove', () => {
      it.each([true, false])('can hide remove button', (showRemoveButton) => {
        createComponent({ props: { showRemoveButton } });
        expect(findRemoveButton().exists()).toBe(showRemoveButton);
      });
    });
  });
});
