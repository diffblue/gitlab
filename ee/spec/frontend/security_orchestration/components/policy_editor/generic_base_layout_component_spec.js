import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('GenericBaseLayoutComponent', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GenericBaseLayoutComponent, {
      propsData: {
        ...props,
      },
    });
  };

  const findBaseLayoutLabel = () => wrapper.findByTestId('base-label');
  const findRemoveButton = () => wrapper.findByTestId('remove-rule');

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display the label', () => {
      expect(findBaseLayoutLabel().exists()).toBe(false);
    });

    it('displays remove button', () => {
      expect(findRemoveButton().exists()).toBe(true);
    });

    it('removes base layout', () => {
      findRemoveButton().vm.$emit('click');
      expect(wrapper.emitted('remove')).toHaveLength(1);
    });
  });

  describe('with custom props', () => {
    it('displays the label', () => {
      createComponent({ ruleLabel: 'ruleLabel' });
      expect(findBaseLayoutLabel().exists()).toBe(true);
    });

    it('hides the remove button', () => {
      createComponent({ showRemoveButton: false });
      expect(findRemoveButton().exists()).toBe(false);
    });
  });
});
