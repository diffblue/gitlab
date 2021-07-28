import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { WIDGET } from 'ee/contextual_sidebar/components/constants';
import TrialStatusWidget from 'ee/contextual_sidebar/components/trial_status_widget.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';

describe('TrialStatusWidget component', () => {
  let wrapper;

  const { trackingEvents } = WIDGET;
  const defaultDaysRemaining = 20;

  const findGlLink = () => wrapper.findComponent(GlLink);

  const createComponent = (providers = {}) => {
    return shallowMount(TrialStatusWidget, {
      provide: {
        daysRemaining: defaultDaysRemaining,
        navIconImagePath: 'illustrations/golden_tanuki.svg',
        percentageComplete: 10,
        planName: 'Ultimate',
        plansHref: 'billing/path-for/group',
        ...providers,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('interpolated strings', () => {
    it('correctly interpolates them all', () => {
      wrapper = createComponent();

      expect(wrapper.text()).not.toMatch(/%{\w+}/);
    });
  });

  describe('without the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders without an id', () => {
      expect(findGlLink().attributes('id')).toBe(undefined);
    });

    it('tracks when the widget is clicked', () => {
      const { action, ...options } = trackingEvents.widgetClick;
      const trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

      findGlLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, action, {
        ...options,
        value: defaultDaysRemaining,
      });

      unmockTracking();
    });
  });

  describe('with the optional containerId prop', () => {
    beforeEach(() => {
      wrapper = createComponent({ containerId: 'some-id' });
    });

    it('renders with the given id', () => {
      expect(findGlLink().attributes('id')).toBe('some-id');
    });
  });
});
