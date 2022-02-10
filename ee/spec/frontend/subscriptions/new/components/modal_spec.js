import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import createStore from 'ee/subscriptions/new/store';
import Component from 'ee/subscriptions/new/components/modal.vue';
import { MODAL_TITLE, MODAL_BODY, TRACKING_EVENTS } from 'ee/subscriptions/new/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import installGlEmojiElement from '~/behaviors/gl_emoji';

describe('Modal component', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = (trial = false) => {
    return extendedWrapper(
      shallowMount(Component, {
        store: createStore({ trial, newTrialRegistrationPath: 'newTrialRegistrationPath' }),
        stubs: { GlModal },
      }),
    );
  };

  const expectTracking = ({ action, ...options } = {}) => {
    return expect(trackingSpy).toHaveBeenCalledWith(undefined, action, { ...options });
  };

  beforeAll(() => {
    installGlEmojiElement();
  });

  beforeEach(() => {
    wrapper = createComponent();
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders modal title and body', () => {
    const modalText = wrapper.text();

    expect(modalText).toContain(MODAL_TITLE);
    expect(modalText).toContain(MODAL_BODY);
  });

  it('tracks when modal-close-btn is clicked', () => {
    wrapper.findByTestId('modal-close-btn').vm.$emit('click');

    expectTracking(TRACKING_EVENTS.cancel);
  });

  it('tracks when talk-to-sales-btn is clicked', () => {
    wrapper.findByTestId('talk-to-sales-btn').vm.$emit('click');

    expectTracking(TRACKING_EVENTS.talkToSales);
  });

  it('tracks when start-free-trial-btn is clicked', () => {
    wrapper.findByTestId('start-free-trial-btn').vm.$emit('click');

    expectTracking(TRACKING_EVENTS.startFreeTrial);
  });

  it('tracks when modal is dismissed', () => {
    wrapper.findComponent(GlModal).vm.$emit('close');

    expectTracking(TRACKING_EVENTS.dismiss);
  });

  describe('when user is on trial', () => {
    beforeEach(() => {
      wrapper = createComponent(true);
    });

    it('does not render start-free-trial-btn', () => {
      expect(wrapper.findByTestId('start-free-trial-btn').exists()).toBe(false);
    });
  });
});
