import { GlPopover } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import {
  POPOVER,
  TRACKING_PROPERTY_WHEN_FORCED,
  TRACKING_PROPERTY_WHEN_VOLUNTARY,
} from 'ee/contextual_sidebar/components/constants';
import TrialStatusPopover from 'ee/contextual_sidebar/components/trial_status_popover.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import axios from '~/lib/utils/axios_utils';

Vue.config.ignoredElements = ['gl-emoji'];

describe('TrialStatusPopover component', () => {
  let wrapper;
  let trackingSpy;

  const { trackingEvents } = POPOVER;
  const defaultDaysRemaining = 20;

  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findByRef = (ref) => wrapper.find({ ref });

  const expectTracking = ({ action, ...options } = {}) => {
    return expect(trackingSpy).toHaveBeenCalledWith(undefined, action, {
      property: TRACKING_PROPERTY_WHEN_VOLUNTARY,
      value: defaultDaysRemaining,
      ...options,
    });
  };

  const createComponent = ({ providers = {}, mountFn = shallowMount, stubs = {} } = {}) => {
    return extendedWrapper(
      mountFn(TrialStatusPopover, {
        provide: {
          containerId: undefined,
          daysRemaining: defaultDaysRemaining,
          groupName: 'Some Test Group',
          planName: 'Ultimate',
          plansHref: 'billing/path-for/group',
          purchaseHref: 'transactions/new',
          targetId: 'target-element-identifier',
          trialEndDate: new Date('2021-02-28'),
          userCalloutsPath: undefined,
          userCalloutsFeatureId: undefined,
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
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  describe('interpolated strings', () => {
    it('correctly interpolates them all', () => {
      wrapper = createComponent({ providers: undefined, mountFn: mount });

      expect(wrapper.text()).not.toMatch(/%{\w+}/);
    });
  });

  it('tracks when the compare button is clicked', () => {
    wrapper.findByTestId('compareBtn').vm.$emit('click');

    expectTracking(trackingEvents.compareBtnClick);
  });

  it('does not include the word "Trial" if the plan name includes it', () => {
    wrapper = createComponent({ providers: { planName: 'Ultimate Trial' }, mountFn: mount });

    const popoverText = wrapper.text();

    expect(popoverText).toContain('We hope you’re enjoying the features of GitLab Ultimate.');
    expect(popoverText).toMatch(/Upgrade Some Test Group to Ultimate(?! Trial)/);
  });

  describe('group_contact_sales experiment', () => {
    describe('control', () => {
      beforeEach(() => {
        stubExperiments({ group_contact_sales: 'control' });
        wrapper = createComponent({ stubs: { GitlabExperiment } });
        trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('tracks when the upgrade button is clicked', () => {
        findByRef('upgradeBtn').vm.$emit('click');

        expectTracking(trackingEvents.upgradeBtnClick);
      });
    });

    describe('candidate', () => {
      beforeEach(() => {
        stubExperiments({ group_contact_sales: 'candidate' });
        wrapper = createComponent({ stubs: { GitlabExperiment } });
        trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('tracks when the contact sales button is clicked', () => {
        wrapper.findByTestId('contactSalesBtn').trigger('click');

        expectTracking(trackingEvents.contactSalesBtnClick);
      });
    });
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
        wrapper = createComponent({ providers: { startInitiallyShown: true } });
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
            providers: {
              startInitiallyShown: true,
              ...userCalloutProviders,
            },
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
        wrapper = createComponent({ providers: { ...userCalloutProviders } });
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
        wrapper = createComponent({ providers: { startInitiallyShown: true }, mountFn: mount });
      });

      it('is enabled', () => {
        expect(findGlPopover().props('showCloseButton')).toBe(true);
      });

      describe('when clicked', () => {
        const preventDefault = jest.fn();

        beforeEach(async () => {
          findGlPopover().vm.$emit('close-button-clicked', {
            preventDefault,
          });
          await nextTick();
        });

        it("calls `preventDefault` so user doesn't trigger the anchor tag", () => {
          expect(preventDefault).toHaveBeenCalled();
        });

        it('closes the popover component', () => {
          expect(findGlPopover().props('show')).toBeFalsy();
        });

        it('tracks an event', () => {
          expectTracking(trackingEvents.closeBtnClick);
        });

        it('continues to be shown in the popover', () => {
          expect(findGlPopover().props('showCloseButton')).toBe(true);
        });
      });
    });

    describe('when the popover does not start off forcibly shown', () => {
      it('is not rendered', () => {
        expect(findGlPopover().props('showCloseButton')).toBe(false);
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

  describe('trackingPropertyAndValue', () => {
    it.each`
      daysRemaining | startInitiallyShown | property
      ${14}         | ${false}            | ${TRACKING_PROPERTY_WHEN_VOLUNTARY}
      ${14}         | ${true}             | ${TRACKING_PROPERTY_WHEN_FORCED}
    `(
      'sets the expected values for `property` & `value`',
      ({ daysRemaining, startInitiallyShown, property }) => {
        wrapper = createComponent({ providers: { daysRemaining, startInitiallyShown } });

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
