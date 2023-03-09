import { GlPopover } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import timezoneMock from 'timezone-mock';
import { POPOVER } from 'ee/contextual_sidebar/components/constants';
import TrialStatusPopover from 'ee/contextual_sidebar/components/trial_status_popover.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';

Vue.config.ignoredElements = ['gl-emoji'];

describe('TrialStatusPopover component', () => {
  let wrapper;
  let trackingSpy;

  const { trackingEvents } = POPOVER;
  const defaultDaysRemaining = 20;

  const findGlPopover = () => wrapper.findComponent(GlPopover);

  const expectTracking = ({ action, ...options } = {}) => {
    return expect(trackingSpy).toHaveBeenCalledWith(undefined, action, { ...options });
  };

  const createComponent = ({ providers = {}, mountFn = shallowMount, stubs = {} } = {}) => {
    return extendedWrapper(
      mountFn(TrialStatusPopover, {
        provide: {
          containerId: undefined,
          daysRemaining: defaultDaysRemaining,
          planName: 'Ultimate',
          plansHref: 'billing/path-for/group',
          targetId: 'target-element-identifier',
          trialEndDate: new Date('2021-02-21'),
          user: {
            namespaceId: 'namespaceId',
            userName: 'userName',
            firstName: 'firstName',
            lastName: 'lastName',
            companyName: 'companyName',
            glmContent: 'glmContent',
          },
          ...providers,
        },
        stubs,
      }),
    );
  };

  beforeEach(() => {
    wrapper = createComponent();
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('interpolated strings', () => {
    it('correctly interpolates them all', () => {
      wrapper = createComponent({ providers: undefined, mountFn: mount });

      expect(wrapper.text()).not.toMatch(/%{\w+}/);
    });
  });

  describe('title', () => {
    it('correctly displays when days remaining is 1', () => {
      wrapper = createComponent({ providers: { daysRemaining: 1 }, mountFn: mount });

      expect(wrapper.text()).toContain(__("You've got 1 day remaining on GitLab Ultimate!"));
    });

    it('correct displays when days remaining is 30', () => {
      wrapper = createComponent({ providers: { daysRemaining: 30 }, mountFn: mount });

      expect(wrapper.text()).toContain(__("You've got 30 days remaining on GitLab Ultimate!"));
    });
  });

  it('tracks when the contact sales button is clicked', () => {
    wrapper.findByTestId('contact-sales-btn').trigger('click');

    expectTracking(trackingEvents.contactSalesBtnClick);
  });

  it('tracks when the compare button is clicked', () => {
    wrapper.findByTestId('compare-btn').vm.$emit('click');

    expectTracking(trackingEvents.compareBtnClick);
  });

  it('does not include the word "Trial" if the plan name includes it', () => {
    wrapper = createComponent({ providers: { planName: 'Ultimate Trial' }, mountFn: mount });

    const popoverText = wrapper.text();

    expect(popoverText).toContain('We hope you’re enjoying the features of GitLab Ultimate.');
  });

  describe('correct date in different timezone', () => {
    beforeEach(() => {
      timezoneMock.register('US/Pacific');
    });

    afterEach(() => {
      timezoneMock.unregister();
    });

    it('converts date correctly to UTC', () => {
      wrapper = createComponent({ providers: { planName: 'Ultimate Trial' }, mountFn: mount });

      const popoverText = wrapper.text();

      expect(popoverText).toContain('February 21');
    });
  });

  describe('methods', () => {
    describe('updateDisabledState', () => {
      it.each`
        bp      | isDisabled
        ${'xs'} | ${'true'}
        ${'sm'} | ${'true'}
        ${'md'} | ${undefined}
        ${'lg'} | ${undefined}
        ${'xl'} | ${undefined}
      `(
        'sets disabled to `$isDisabled` when the breakpoint is "$bp"',
        async ({ bp, isDisabled }) => {
          jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue(bp);

          window.dispatchEvent(new Event('resize'));
          await nextTick();

          expect(findGlPopover().attributes('disabled')).toBe(isDisabled);
        },
      );
    });

    describe('onShown', () => {
      it('dispatches tracking event', () => {
        findGlPopover().vm.$emit('shown');

        expectTracking(trackingEvents.popoverShown);
      });
    });
  });
});
