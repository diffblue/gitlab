import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiVariableSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/ci_variable_selector.vue';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';

describe('CiVariableSelector', () => {
  let wrapper;

  const VARIABLE_EXAMPLE = 'DAST_PATHS_FILE';
  const PREVIOUSLY_SELECTED_VARIABLE_EXAMPLE = 'DAST_ADVERTISE_SCAN';
  const VALUE = 'Test value';

  const DEFAULT_PROPS = {
    scanType: 'dast',
    selected: {},
    variable: '',
    value: '',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(CiVariableSelector, {
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      stubs: { GenericBaseLayoutComponent },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findFormInput = () => wrapper.findComponent(GlFormInput);
  const findGenericBaseLayoutComponent = () => wrapper.findComponent(GenericBaseLayoutComponent);

  describe('empty variable', () => {
    beforeEach(() => {
      createComponent({ propsData: { selected: { [PREVIOUSLY_SELECTED_VARIABLE_EXAMPLE]: '' } } });
    });

    describe('dropdown', () => {
      it('displays the dropdown with the correct props based on scan type', () => {
        expect(findDropdown().props('toggleText')).toBe('Select a variable');
        expect(findDropdown().props('items')).toContainEqual({
          text: VARIABLE_EXAMPLE,
          value: VARIABLE_EXAMPLE,
        });
      });

      it('updates the list items when searching', async () => {
        await findDropdown().vm.$emit('search', VARIABLE_EXAMPLE);
        expect(findDropdown().props('items')).toEqual([
          { text: VARIABLE_EXAMPLE, value: VARIABLE_EXAMPLE },
        ]);
      });

      it('does not display previously selected variables as options', () => {
        expect(findDropdown().props('items')).not.toContainEqual({
          text: PREVIOUSLY_SELECTED_VARIABLE_EXAMPLE,
          value: PREVIOUSLY_SELECTED_VARIABLE_EXAMPLE,
        });
      });

      it('emits "input" when an item is selected', () => {
        findDropdown().vm.$emit('select', VARIABLE_EXAMPLE);
        expect(wrapper.emitted('input')).toEqual([[[VARIABLE_EXAMPLE, '']]]);
      });
    });

    describe('value input', () => {
      it('displays the form input with the correct props', () => {
        expect(findFormInput().attributes('value')).toBe('');
      });

      it('updates the value when the input is changed', () => {
        findFormInput().vm.$emit('input', VALUE);
        expect(wrapper.emitted('input')).toEqual([[['', VALUE]]]);
      });
    });

    it('emits "remove" event when a user removes the variable', () => {
      findGenericBaseLayoutComponent().vm.$emit('remove');
      expect(wrapper.emitted('remove')).toEqual([['']]);
    });
  });

  describe('valid variable', () => {
    beforeEach(() => {
      createComponent({ propsData: { variable: VARIABLE_EXAMPLE, value: VALUE } });
    });

    it('selects the variable from the dropdown', () => {
      expect(findDropdown().props('selected')).toEqual(VARIABLE_EXAMPLE);
    });

    it('displays the correct toggle text if an item is selected', () => {
      expect(findDropdown().props('toggleText')).toBe(VARIABLE_EXAMPLE);
    });

    it('displays the form input with the correct props', () => {
      expect(findFormInput().attributes('value')).toBe(VALUE);
    });
  });

  describe('invalid variable', () => {
    it('emits "error" when a variable does not exist in the list', () => {
      const INVALID_VARIABLE = 'Test Variable';
      createComponent({ propsData: { variable: INVALID_VARIABLE, value: VALUE } });
      expect(wrapper.emitted('error')).toEqual([[]]);
    });
  });
});
