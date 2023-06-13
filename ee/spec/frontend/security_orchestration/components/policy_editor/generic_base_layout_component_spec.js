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
  const findContent = () => wrapper.findByTestId('content');
  const findRemoveButton = () => wrapper.findByTestId('remove-rule');

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });
    it('displays the content with the correct layout', () => {
      expect(findContent().attributes('class')).toBe(
        'gl-flex-grow-1 gl-w-full gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap ',
      );
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
    it('renders with custom CSS class', () => {
      const CUSTOM_CLASS = 'custom-class';
      createComponent({ contentClasses: CUSTOM_CLASS });
      expect(findContent().attributes('class')).toContain(CUSTOM_CLASS);
    });

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
