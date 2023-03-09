import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Target from 'ee/security_configuration/corpus_management/components/columns/target.vue';

describe('Target', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = { target: '294444-apollo-management-table' };
    wrapper = mountFn(Target, {
      propsData: defaultProps,
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  describe('component', () => {
    it('renders target', () => {
      createComponent();
      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('without target', () => {
      it('renders Not Set with icon', () => {
        createComponent({ propsData: { target: '' } });
        expect(wrapper.findComponent(GlIcon).exists()).toBe(true);
        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });
});
