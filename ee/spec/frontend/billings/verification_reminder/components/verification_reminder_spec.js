import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import VerificationReminder from 'ee/billings/verification_reminder/components/verification_reminder.vue';
import { TEST_HOST } from 'helpers/test_constants';
import {
  EVENT_LABEL,
  MOUNTED_EVENT,
  DISMISS_EVENT,
  OPEN_DOCS_EVENT,
  START_VERIFICATION_EVENT,
  SUCCESSFUL_VERIFICATION_EVENT,
} from 'ee/billings/verification_reminder/constants';

describe('VerificationReminder', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = ({ shouldShowCallout = true } = {}, data = {}) => {
    wrapper = shallowMount(VerificationReminder, {
      data() {
        return data;
      },
      stubs: {
        GlSprintf,
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          shouldShowCallout,
        }),
      },
    });
  };

  const findVerificationModal = () => wrapper.findComponent({ ref: 'modal' });
  const calloutDismisser = () => wrapper.findComponent({ ref: 'calloutDismisser' });
  const findWarningAlert = () => wrapper.findComponent({ ref: 'warningAlert' });
  const findSuccessAlert = () => wrapper.findComponent({ ref: 'successAlert' });
  const findValidateLink = () => wrapper.findComponent({ ref: 'validateLink' });
  const findDocsLink = () => wrapper.findComponent({ ref: 'docsLink' });

  beforeEach(() => {
    window.gon = {
      subscriptions_url: TEST_HOST,
      payment_form_url: TEST_HOST,
    };
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

    createComponent();

    findVerificationModal().vm.show = jest.fn();
    findVerificationModal().vm.hide = jest.fn();
    calloutDismisser().vm.dismiss = jest.fn();
  });

  afterEach(() => {
    window.gon = {};
    unmockTracking();
    wrapper.destroy();
  });

  describe('when the component is mounted', () => {
    it('sends the mounted event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, MOUNTED_EVENT, {
        label: EVENT_LABEL,
      });
    });

    it('renders the warning alert', () => {
      expect(findWarningAlert().exists()).toBe(true);
    });
  });

  describe('when dismissing the alert', () => {
    beforeEach(() => {
      findWarningAlert().vm.$emit('dismiss');
    });

    it('sends the dismiss event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, DISMISS_EVENT, {
        label: EVENT_LABEL,
      });
    });

    it('calls the dismiss callback', () => {
      expect(calloutDismisser().vm.dismiss).toHaveBeenCalled();
    });
  });

  describe('when the alert has been dismissed', () => {
    beforeEach(() => {
      createComponent({
        shouldShowCallout: false,
      });
    });

    it('hides the warning alert', () => {
      expect(findWarningAlert().exists()).toBe(false);
    });
  });

  describe('when the validate link is clicked', () => {
    beforeEach(() => {
      findValidateLink().vm.$emit('click');
    });

    it('sends the start verification event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, START_VERIFICATION_EVENT, {
        label: EVENT_LABEL,
      });
    });

    it('shows the verification modal', () => {
      expect(findVerificationModal().vm.show).toHaveBeenCalled();
    });
  });

  describe('when the docs link is clicked', () => {
    beforeEach(() => {
      findDocsLink().vm.$emit('click');
    });

    it('sends the open docs event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, OPEN_DOCS_EVENT, {
        label: EVENT_LABEL,
      });
    });
  });

  describe('when validation was successful', () => {
    beforeEach(() => {
      findVerificationModal().vm.$emit('success');
    });

    it('sends the successful verification event', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, SUCCESSFUL_VERIFICATION_EVENT, {
        label: EVENT_LABEL,
      });
    });

    it('hides the modal', () => {
      expect(findVerificationModal().vm.hide).toHaveBeenCalled();
    });

    it('calls the dismiss callback', () => {
      expect(calloutDismisser().vm.dismiss).toHaveBeenCalled();
    });

    it('renders the success alert', () => {
      expect(findSuccessAlert().exists()).toBe(true);
    });
  });

  describe('when dismissing the success alert', () => {
    beforeEach(() => {
      createComponent(undefined, {
        shouldRenderSuccess: true,
      });
      findSuccessAlert().vm.$emit('dismiss');
    });

    it('hides the success alert', () => {
      expect(findSuccessAlert().exists()).toBe(false);
    });
  });
});
