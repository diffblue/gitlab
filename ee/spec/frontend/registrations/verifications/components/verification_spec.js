import { GlButton, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Verification from 'ee/registrations/verification/components/verification.vue';
import {
  IFRAME_MINIMUM_HEIGHT,
  EVENT_LABEL,
  MOUNTED_EVENT,
  SKIPPED_EVENT,
  VERIFIED_EVENT,
} from 'ee/registrations/verification/constants';

jest.mock('~/lib/utils/url_utility');

describe('Verification', () => {
  let wrapper;
  let trackingSpy;
  let zuoraSubmitSpy;

  const NEXT_STEP_URL = 'https://gitlab.com/next-step';
  const IFRAME_URL = 'https://customers.gitlab.com/payment_forms/cc_registration_validation';
  const ALLOWED_ORIGIN = 'https://customers.gitlab.com';

  const createComponent = () => {
    return shallowMount(Verification, {
      provide: {
        nextStepUrl: NEXT_STEP_URL,
      },
      stubs: {
        GlButton,
        GlPopover,
      },
    });
  };

  const findSubmitButton = () => wrapper.findComponent({ ref: 'submitButton' });
  const findZuora = () => wrapper.findComponent({ ref: 'zuora' });
  const findSkipLink = () => wrapper.findComponent({ ref: 'skipLink' });
  const findPopover = () => wrapper.findComponent({ ref: 'popover' });
  const findPopoverClose = () => wrapper.findComponent({ ref: 'popoverClose' });
  const findSkipConfirmationLink = () => wrapper.findComponent({ ref: 'skipConfirmationLink' });

  const expectRedirect = () => expect(redirectTo).toHaveBeenCalledWith(NEXT_STEP_URL); // eslint-disable-line import/no-deprecated
  const expectTrackingOfEvent = (event) => {
    expect(trackingSpy).toHaveBeenCalledWith(undefined, event, {
      label: EVENT_LABEL,
    });
  };

  beforeEach(() => {
    window.gon = {
      registration_validation_form_url: IFRAME_URL,
      subscriptions_url: ALLOWED_ORIGIN,
    };
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
    wrapper = createComponent();
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('when the component is mounted', () => {
    it('sends the mounted event', () => {
      expectTrackingOfEvent(MOUNTED_EVENT);
    });

    it('renders the Zuora component with the right attributes', () => {
      expect(findZuora().exists()).toBe(true);
      expect(findZuora().attributes()).toMatchObject({
        iframeurl: IFRAME_URL,
        allowedorigin: ALLOWED_ORIGIN,
        initialheight: IFRAME_MINIMUM_HEIGHT.toString(),
      });
    });
  });

  describe('when the submit button is clicked', () => {
    beforeEach(() => {
      zuoraSubmitSpy = jest.fn();
      wrapper.vm.$refs.zuora = { submit: zuoraSubmitSpy };
      findSubmitButton().trigger('click');
    });

    it('calls the submit method of the Zuora component', () => {
      expect(zuoraSubmitSpy).toHaveBeenCalled();
    });
  });

  describe('when the Zuora component emits a success event', () => {
    beforeEach(() => {
      findZuora().vm.$emit('success');
    });

    it('tracks the verified event', () => {
      expectTrackingOfEvent(VERIFIED_EVENT);
    });

    it('redirects to the provided next step URL', () => {
      expectRedirect();
    });
  });

  describe('when the skip link is clicked', () => {
    beforeEach(() => {
      findSkipLink().trigger('click');
    });

    it('shows the popover', () => {
      expect(findPopover().exists()).toBe(true);
    });

    describe('when the skip confirmation link in the popover is clicked', () => {
      beforeEach(() => {
        findSkipConfirmationLink().vm.$emit('click');
      });

      it('tracks the skipped event', () => {
        expectTrackingOfEvent(SKIPPED_EVENT);
      });

      it('redirects to the provided next step URL', () => {
        expectRedirect();
      });
    });

    describe('when closing the popover', () => {
      beforeEach(() => {
        findPopoverClose().trigger('click');
      });

      it('hides the popover', () => {
        expect(findPopover().exists()).toBe(false);
      });

      describe('when clicking the skip link again', () => {
        beforeEach(() => {
          findSkipLink().trigger('click');
        });

        it('tracks the skipped event', () => {
          expectTrackingOfEvent(SKIPPED_EVENT);
        });

        it('redirects to the provided next step URL', () => {
          expectRedirect();
        });
      });
    });
  });
});
