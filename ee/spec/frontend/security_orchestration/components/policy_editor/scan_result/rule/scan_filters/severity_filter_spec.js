import { GlCollapsibleListbox } from '@gitlab/ui';
import SeverityFilter from 'ee/security_orchestration/components/policy_editor/scan_result/rule/scan_filters/severity_filter.vue';
import SectionLayout from 'ee/security_orchestration/components/policy_editor/section_layout.vue';
import RuleMultiSelect from 'ee/security_orchestration/components/policy_editor/rule_multi_select.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';

describe('FilterSpec', () => {
  let wrapper;
  let testKey1;
  let testKey2;

  const filterOptions = SEVERITY_LEVELS;
  const expectedSelectAllItems = Object.keys(SEVERITY_LEVELS);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(SeverityFilter, {
      propsData: {
        ...props,
      },
      stubs: {
        SectionLayout,
        RuleMultiSelect,
        GlCollapsibleListbox,
      },
    });
  };

  const findPolicyRuleMultiSelect = () => wrapper.findComponent(RuleMultiSelect);
  const findAllSelectedItem = () => wrapper.findByTestId('listbox-select-all-button');

  describe('SeverityFilter', () => {
    describe('new filter', () => {
      beforeEach(() => {
        createComponent();
        [testKey1, testKey2] = Object.keys(filterOptions);
      });

      it('renders filters dropdown', () => {
        expect(findPolicyRuleMultiSelect().exists()).toBe(true);
      });

      it('selects filters', () => {
        findPolicyRuleMultiSelect().vm.$emit('input', [testKey1]);
        findPolicyRuleMultiSelect().vm.$emit('input', [testKey2]);

        expect(wrapper.emitted('input')).toEqual([[[testKey1]], [[testKey2]]]);
      });

      it('selects all items', () => {
        findAllSelectedItem().vm.$emit('click');

        expect(wrapper.emitted('input')).toEqual([[expectedSelectAllItems]]);
      });

      it('selects "null" when no states are selected', () => {
        findPolicyRuleMultiSelect().vm.$emit('input', []);

        expect(wrapper.emitted('input')).toEqual([[null]]);
      });
    });

    describe('existing filter', () => {
      beforeEach(() => {
        createComponent({
          props: { selected: [testKey1, testKey2] },
        });
      });

      it('selects existing filters', () => {
        expect(findPolicyRuleMultiSelect().props('value')).toEqual([testKey1, testKey2]);
      });
    });
  });
});
