import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { mockTracking } from 'helpers/tracking_helper';
import SubscriptionUpgradeInfoCard from 'ee/usage_quotas/seats/components/subscription_upgrade_info_card.vue';
import { EXPLORE_PAID_PLANS_CLICKED } from 'ee/usage_quotas/seats/constants';

describe('SubscriptionUpgradeInfoCard', () => {
  let trackingSpy;
  let wrapper;

  const defaultProps = {
    maxNamespaceSeats: 5,
    explorePlansPath: 'http://test.gitlab.com/',
  };

  const createComponent = (props = {}) => {
    wrapper = mount(SubscriptionUpgradeInfoCard, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findTitle = () => wrapper.find('[data-testid="title"]');
  const findDescription = () => wrapper.find('[data-testid="description"]');
  const findExplorePlansLink = () => wrapper.findComponent(GlButton);

  describe('when not in an active trial', () => {
    beforeEach(() => {
      createComponent({ activeTrial: false });
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('renders help link if description and helpLink props are passed', () => {
      expect(findExplorePlansLink().attributes('href')).toBe(defaultProps.explorePlansPath);
    });

    it('renders title message with max number of seats', () => {
      expect(findTitle().text()).toContain('limited to 5 seats');
    });

    it('renders description message with max number of seats', () => {
      expect(findDescription().text()).toContain(
        'To ensure all members can access the group when your trial ends, you can upgrade to a paid tier.',
      );
    });

    it('tracks on click', () => {
      const link = findExplorePlansLink();

      link.vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: EXPLORE_PAID_PLANS_CLICKED,
      });
    });
  });

  describe('when in an active trial', () => {
    beforeEach(() => {
      createComponent({ activeTrial: true });
    });

    it('renders title message with "during your trial"', () => {
      expect(findTitle().text()).toBe('Unlimited members during your trial');
    });
  });
});
