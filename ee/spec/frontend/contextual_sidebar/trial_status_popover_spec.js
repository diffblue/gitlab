import { GlPopover } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import timezoneMock from 'timezone-mock';
import { POPOVER } from 'ee/contextual_sidebar/components/constants';
import TrialStatusPopover from 'ee/contextual_sidebar/components/trial_status_popover.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';

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
          groupName: 'Some Test Group',
          planName: 'Ultimate',
          plansHref: 'billing/path-for/group',
          purchaseHref: 'transactions/new',
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
    wrapper.findByTestId('compare-btn').vm.$emit('click');

    expectTracking(trackingEvents.compareBtnClick);
  });

  it('does not include the word "Trial" if the plan name includes it', () => {
    wrapper = createComponent({ providers: { planName: 'Ultimate Trial' }, mountFn: mount });

    const popoverText = wrapper.text();

    expect(popoverText).toContain('We hope you’re enjoying the features of GitLab Ultimate.');
    expect(popoverText).toMatch(/Upgrade Some Test Group to Ultimate(?! Trial)/);
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

  describe('group_contact_sales experiment', () => {
    describe('control', () => {
      beforeEach(() => {
        stubExperiments({ group_contact_sales: 'control' });
        wrapper = createComponent({ stubs: { GitlabExperiment } });
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders the upgrade button', () => {
        expect(wrapper.findByTestId('upgrade-btn').exists()).toBe(true);
      });
    });

    describe('candidate', () => {
      beforeEach(() => {
        stubExperiments({ group_contact_sales: 'candidate' });
        wrapper = createComponent({ stubs: { GitlabExperiment } });
        trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('tracks when the contact sales button is clicked', () => {
        wrapper.findByTestId('contact-sales-btn').trigger('click');

        expectTracking({ ...trackingEvents.contactSalesBtnClick, context: expect.any(Object) });
      });
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

        expectTracking({ ...trackingEvents.popoverShown, context: expect.any(Object) });
      });
    });
  });
});
