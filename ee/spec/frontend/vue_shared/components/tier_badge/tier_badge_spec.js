import { shallowMount } from '@vue/test-utils';
import TierBadge from 'ee/vue_shared/components/tier_badge/tier_badge.vue';

describe('TierBadge', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(TierBadge, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with default props', () => {
    it('renders the default tier', () => {
      createComponent();

      expect(wrapper.text()).toBe('Free');
    });
  });

  describe('when tier is passed in', () => {
    it('renders the passed in tier', () => {
      createComponent({ props: { tier: 'Ultimate' } });

      expect(wrapper.text()).toBe('Ultimate');
    });
  });
});
