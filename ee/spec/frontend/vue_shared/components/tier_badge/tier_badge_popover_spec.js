import { mountExtended } from 'helpers/vue_test_utils_helper';
import TierBadgePopover from 'ee/vue_shared/components/tier_badge/tier_badge_popover.vue';
import { mockTracking } from 'helpers/tracking_helper';

describe('TierBadgePopover', () => {
  let wrapper;

  const primaryCTALink = '#trials/new';
  const secondaryCTALink = '#/groups/foobar-group/-/billings?source=overview-free-tier-highlight';
  const popoverTitle = 'Enhance team productivity';
  const popoverContentForGroup =
    'This group and all its related projects use the Free GitLab tier. Want to enhance team productivity and access advanced features like Merge Approvals, Push rules, Epics, Code Review Analytics, and Container Scanning? Try all GitLab has to offer for free for 30 days. No credit card required.';
  const popoverContentForProject =
    'This project uses the Free GitLab tier. Want to enhance team productivity and access advanced features like Merge Approvals, Push rules, Epics, Code Review Analytics, and Container Scanning? Try all GitLab has to offer for free for 30 days. No credit card required.';
  const primaryCTAText = 'Start a free trial';
  const secondaryCTAText = 'Explore paid plans';
  const findPrimaryCTA = () => wrapper.findByTestId('tier-badge-popover-primary-cta');
  const findSecondaryCTA = () => wrapper.findByTestId('tier-badge-popover-secondary-cta');

  const createComponent = ({ props, provide } = { props: {}, provide: {} }) => {
    wrapper = mountExtended(TierBadgePopover, {
      provide: {
        primaryCtaLink: primaryCTALink,
        secondaryCtaLink: secondaryCTALink,
        sourceType: 'Group',
        ...provide,
      },
      propsData: {
        popoverId: '1',
        tier: 'Free',
        ...props,
      },
    });
  };

  describe('with title and content', () => {
    describe('when sourceType is provided', () => {
      it('renders the title and correct content for `Group`', () => {
        createComponent({ provide: { sourceType: 'Group' } });

        expect(wrapper.findByText(popoverTitle).exists()).toBe(true);
        expect(wrapper.findByText(popoverContentForGroup).exists()).toBe(true);
      });

      it('renders the title and correct content for `Project`', () => {
        createComponent({ provide: { sourceType: 'Project' } });

        expect(wrapper.findByText(popoverTitle).exists()).toBe(true);
        expect(wrapper.findByText(popoverContentForProject).exists()).toBe(true);
      });
    });

    describe('with CTAs', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the `Start a free trial` cta button', () => {
        expect(findPrimaryCTA().text()).toEqual(primaryCTAText);
        expect(findPrimaryCTA().attributes('href')).toEqual(primaryCTALink);
      });

      it('renders the `Explore paid plans` cta button', () => {
        expect(findSecondaryCTA().text()).toEqual(secondaryCTAText);
        expect(findSecondaryCTA().attributes('href')).toEqual(secondaryCTALink);
      });

      describe('tracking', () => {
        it('tracks primary CTA', () => {
          const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
          findPrimaryCTA().trigger('click');
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_start_trial_button', {
            label: 'tier-badge',
          });
        });

        it('tracks secondary CTA', () => {
          const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
          findSecondaryCTA().trigger('click');
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_compare_plans_button', {
            label: 'tier-badge',
          });
        });
      });
    });
  });
});
