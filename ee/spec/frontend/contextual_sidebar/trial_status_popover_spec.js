import { GlPopover } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import {
  POPOVER,
  TRACKING_PROPERTY_WHEN_FORCED,
  TRACKING_PROPERTY_WHEN_VOLUNTARY,
} from 'ee/contextual_sidebar/components/constants';
import TrialStatusPopover from 'ee/contextual_sidebar/components/trial_status_popover.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';

Vue.config.ignoredElements = ['gl-emoji'];

describe('TrialStatusPopover component', () => {
  let wrapper;
  let trackingSpy;

  const { trackingEvents } = POPOVER;
  const defaultDaysRemaining = 20;

  const findGlPopover = () => wrapper.findComponent(GlPopover);

  const expectTracking = ({ action, ...options } = {}) => {
    return expect(trackingSpy).toHaveBeenCalledWith(undefined, action, {
      property: TRACKING_PROPERTY_WHEN_VOLUNTARY,
      value: defaultDaysRemaining,
      ...options,
    });
  };

  const createComponent = (providers = {}, mountFn = shallowMount) => {
    return extendedWrapper(
      mountFn(TrialStatusPopover, {
        provide: {
          containerId: undefined,
          daysRemaining: defaultDaysRemaining,
          groupName: 'Some Test Group',
          planName: 'Ultimate',
          plansHref: 'billing/path-for/group',
          purchaseHref: 'transactions/new',
          startInitiallyShown: undefined,
          targetId: 'target-element-identifier',
          trialEndDate: new Date('2021-02-28'),
          userCalloutsPath: undefined,
          userCalloutsFeatureId: undefined,
          ...providers,
        },
      }),
    );
  };

  beforeEach(() => {
    wrapper = createComponent();
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  describe('interpolated strings', () => {
    it('correctly interpolates them all', () => {
      wrapper = createComponent(undefined, mount);

      expect(wrapper.text()).not.toMatch(/%{\w+}/);
    });
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('tracks when the upgrade button is clicked', () => {
    wrapper.findByTestId('upgradeBtn').vm.$emit('click');

    expectTracking(trackingEvents.upgradeBtnClick);
  });

  it('tracks when the compare button is clicked', () => {
    wrapper.findByTestId('compareBtn').vm.$emit('click');

    expectTracking(trackingEvents.compareBtnClick);
  });

  describe('startInitiallyShown', () => {
    const userCalloutProviders = {
      userCalloutsPath: 'user_callouts/path',
      userCalloutsFeatureId: 'feature_id',
    };

    beforeEach(() => {
      jest.spyOn(axios, 'post').mockResolvedValue('success');
    });

    describe('when set to true', () => {
      beforeEach(() => {
        wrapper = createComponent({ startInitiallyShown: true });
      });

      it('causes the popover to be shown by default', () => {
        expect(findGlPopover().attributes('show')).toBeTruthy();
      });

      it('removes the popover triggers', () => {
        expect(findGlPopover().attributes('triggers')).toBe('');
      });

      describe('and the user callout values are provided', () => {
        beforeEach(() => {
          wrapper = createComponent({
            startInitiallyShown: true,
            ...userCalloutProviders,
          });
        });

        it('sends a request to update the specified UserCallout record', () => {
          expect(axios.post).toHaveBeenCalledWith(userCalloutProviders.userCalloutsPath, {
            feature_name: userCalloutProviders.userCalloutsFeatureId,
          });
        });
      });

      describe('but the user callout values are not provided', () => {
        it('does not send a request to update a UserCallout record', () => {
          expect(axios.post).not.toHaveBeenCalled();
        });
      });
    });

    describe('when set to false', () => {
      beforeEach(() => {
        wrapper = createComponent({ ...userCalloutProviders });
      });

      it('does not cause the popover to be shown by default', () => {
        expect(findGlPopover().attributes('show')).toBeFalsy();
      });

      it('uses the standard triggers for the popover', () => {
        expect(findGlPopover().attributes('triggers')).toBe('hover focus');
      });

      it('never sends a request to update a UserCallout record', () => {
        expect(axios.post).not.toHaveBeenCalled();
      });
    });
  });

  describe('close button', () => {
    describe('when the popover starts off forcibly shown', () => {
      beforeEach(() => {
        wrapper = createComponent({ startInitiallyShown: true }, mount);
      });

      it('is rendered', () => {
        expect(wrapper.findByTestId('closeBtn').exists()).toBeTruthy();
      });

      describe('when clicked', () => {
        beforeEach(async () => {
          wrapper.findByTestId('closeBtn').trigger('click');
          await wrapper.vm.$nextTick();
        });

        it('closes the popover component', () => {
          expect(findGlPopover().props('show')).toBeFalsy();
        });

        it('tracks an event', () => {
          expectTracking(trackingEvents.closeBtnClick);
        });

        it('continues to be shown in the popover', () => {
          expect(wrapper.findByTestId('closeBtn').exists()).toBeTruthy();
        });
      });
    });

    describe('when the popover does not start off forcibly shown', () => {
      it('is not rendered', () => {
        expect(wrapper.findByTestId('closeBtn').exists()).toBeFalsy();
      });
    });
  });

  describe('methods', () => {
    describe('onResize', () => {
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

          wrapper.vm.onResize();
          await wrapper.vm.$nextTick();

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

  describe('trackingPropertyAndValue', () => {
    it.each`
      daysRemaining | startInitiallyShown | property
      ${14}         | ${false}            | ${TRACKING_PROPERTY_WHEN_VOLUNTARY}
      ${14}         | ${true}             | ${TRACKING_PROPERTY_WHEN_FORCED}
    `(
      'sets the expected values for `property` & `value`',
      ({ daysRemaining, startInitiallyShown, property }) => {
        wrapper = createComponent({ daysRemaining, startInitiallyShown });

        // We'll use the "onShown" method to exercise trackingPropertyAndValue
        findGlPopover().vm.$emit('shown');

        expectTracking({
          ...trackingEvents.popoverShown,
          property,
          value: daysRemaining,
        });
      },
    );
  });
});
