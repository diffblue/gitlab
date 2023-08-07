import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiVariablesSelectors from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/ci_variables_selectors.vue';
import CiVariableSelector from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/ci_variable_selector.vue';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import { CI_VARIABLE } from 'ee/security_orchestration/components/policy_editor/scan_execution/action/scan_filters/constants';

describe('CiVariablesSelectors', () => {
  let wrapper;

  const DEFAULT_SCAN_TYPE = 'DAST';
  const VARIABLES = { key: 'new key', value: 'new value' };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(CiVariablesSelectors, {
      propsData: {
        scanType: DEFAULT_SCAN_TYPE,
        ...propsData,
      },
      stubs: { GenericBaseLayoutComponent },
    });
  };

  const findAllCiVariableSelectors = () => wrapper.findAllComponents(CiVariableSelector);
  const findCiVariableSelector = () => findAllCiVariableSelectors().at(0);
  const findAddButton = () => wrapper.findComponent(GlButton);
  const findGenericBaseLayoutComponent = () => wrapper.findComponent(GenericBaseLayoutComponent);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the disabled "Add" button', () => {
      expect(findAddButton().attributes('disabled')).toBe('true');
    });

    it('emits "input" with a new variable when the "Add" button is clicked', () => {
      findAddButton().vm.$emit('click');
      expect(wrapper.emitted('input')).toEqual([[{ variables: { '': '' } }]]);
    });

    it('emits "remove" when the "remove" filter button is clicked', () => {
      findGenericBaseLayoutComponent().vm.$emit('remove');
      expect(wrapper.emitted('remove')).toEqual([[CI_VARIABLE]]);
    });

    describe('ci variable selector', () => {
      it('initially displays a single ci variable', () => {
        expect(findAllCiVariableSelectors()).toHaveLength(1);
      });

      it('emits "input" with the updated variable when a variable is updated', () => {
        findCiVariableSelector().vm.$emit('input', [VARIABLES.key, VARIABLES.value]);
        expect(wrapper.emitted('input')).toEqual([
          [{ variables: { [VARIABLES.key]: VARIABLES.value } }],
        ]);
      });
    });
  });

  describe('removing a variable', () => {
    it('emits "input" without the variable when a variable is being removed', () => {
      createComponent({ propsData: { selected: { [VARIABLES.key]: VARIABLES.value, '': '' } } });
      findCiVariableSelector().vm.$emit('remove', VARIABLES.key);
      expect(wrapper.emitted('input')).toEqual([[{ variables: { '': '' } }]]);
    });

    it('emits "remove" when the last ci variable is removed', () => {
      createComponent({ propsData: { selected: { [VARIABLES.key]: VARIABLES.value } } });
      findCiVariableSelector().vm.$emit('remove', VARIABLES.key);
      expect(wrapper.emitted('remove')).toEqual([[CI_VARIABLE]]);
    });
  });
});
