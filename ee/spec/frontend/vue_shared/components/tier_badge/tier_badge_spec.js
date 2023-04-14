import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TierBadge from 'ee/vue_shared/components/tier_badge/tier_badge.vue';
import { mockTracking } from 'helpers/tracking_helper';

describe('TierBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findByTestId('tier-badge');
  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(TierBadge, {
      propsData: {
        ...props,
      },
    });
  };

  describe('tracking', () => {
    it('tracks render on mount', () => {
      const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

      createComponent();
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render_badge', { label: 'tier-badge' });
    });

    it('tracks when popover shown', () => {
      const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      createComponent();

      findBadge().trigger('mouseover');
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render_flyout', { label: 'tier-badge' });
    });
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
