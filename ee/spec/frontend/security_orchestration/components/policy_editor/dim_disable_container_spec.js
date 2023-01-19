import { shallowMount } from '@vue/test-utils';
import DimDisableContainer from 'ee/security_orchestration/components/policy_editor/dim_disable_container.vue';

describe('DimDisableContainer component', () => {
  let wrapper;

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMount(DimDisableContainer, {
      propsData: {
        ...propsData,
      },
      slots: {
        default: '<main>Item</main>',
        title: '<h1>Title</h1>',
        disabled: '<span>Disabled</span>',
      },
    });
  };

  beforeEach(() => {
    factory();
  });

  it('renders title slot component', () => {
    expect(wrapper.find('h1').exists()).toBe(true);
  });

  it('renders default slot component', () => {
    expect(wrapper.find('main').exists()).toBe(true);
  });

  it('does not render disabled slot component', () => {
    expect(wrapper.find('span').exists()).toBe(false);
  });

  it('does not render dim overlay', () => {
    expect(wrapper.find("[data-testid='overlay']").exists()).toBe(false);
  });

  describe('give disabled is true', () => {
    beforeEach(() => {
      factory({
        propsData: {
          disabled: true,
        },
      });
    });

    it('renders title slot component', () => {
      expect(wrapper.find('h1').exists()).toBe(true);
    });

    it('does not render default slot component', () => {
      expect(wrapper.find('main').exists()).toBe(false);
    });

    it('renders disabled slot component', () => {
      expect(wrapper.find('span').exists()).toBe(true);
    });

    it('renders dim overlay', () => {
      expect(wrapper.find("[data-testid='overlay']").exists()).toBe(true);
    });
  });
});
