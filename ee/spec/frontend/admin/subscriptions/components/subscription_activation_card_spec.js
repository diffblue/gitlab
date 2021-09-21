import { GlCard, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionActivationCard, {
  activateSubscriptionUrl,
} from 'ee/admin/subscriptions/show/components/subscription_activation_card.vue';
import SubscriptionActivationErrors from 'ee/admin/subscriptions/show/components/subscription_activation_errors.vue';
import SubscriptionActivationForm from 'ee/admin/subscriptions/show/components/subscription_activation_form.vue';
import {
  CONNECTIVITY_ERROR,
  SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
  uploadLicenseFile,
} from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { license } from '../mock_data';

describe('CloudLicenseApp', () => {
  let wrapper;

  const licenseUploadPath = 'license/upload';
  const findSubscriptionActivationForm = () => wrapper.findComponent(SubscriptionActivationForm);
  const findSubscriptionActivationErrors = () =>
    wrapper.findComponent(SubscriptionActivationErrors);
  const findActivateSubscriptionLink = () => wrapper.findByTestId('activate-subscription-link');
  const findUploadLink = () => wrapper.findByTestId('upload-license-link');

  const createComponent = ({ props = {}, stubs = {}, provide = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionActivationCard, {
        propsData: {
          ...props,
        },
        provide: {
          licenseUploadPath,
          ...provide,
        },
        stubs,
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows a form', () => {
    expect(findSubscriptionActivationForm().exists()).toBe(true);
  });

  it('does not show any alert', () => {
    expect(findSubscriptionActivationErrors().exists()).toBe(false);
  });

  describe('with an upload legacy license link', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlCard, GlSprintf } });
    });

    it('shows a link when provided', () => {
      expect(findUploadLink().text()).toBe(uploadLicenseFile);
    });

    it('shows an help link', () => {
      expect(findActivateSubscriptionLink().attributes('href')).toBe(activateSubscriptionUrl);
    });

    it('provides the correct path', () => {
      expect(findUploadLink().attributes('href')).toBe(licenseUploadPath);
    });
  });

  it('does not show a link when legacy license link is not provided', () => {
    createComponent({
      stubs: { GlCard },
      provide: {
        licenseUploadPath: '',
      },
    });

    expect(findUploadLink().exists()).toBe(false);
  });

  describe('when the forms emits a success', () => {
    beforeEach(() => {
      createComponent();
      findSubscriptionActivationForm().vm.$emit(
        SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
        license.ULTIMATE,
      );
    });

    it('passes on the event to the parent component', () => {
      expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT).length).toBe(1);
      expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT)[0]).toEqual([license.ULTIMATE]);
    });
  });

  describe('when the forms emits a connectivity error', () => {
    beforeEach(() => {
      createComponent();
      findSubscriptionActivationForm().vm.$emit(
        SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
        CONNECTIVITY_ERROR,
      );
    });

    it('shows an alert component', () => {
      expect(findSubscriptionActivationErrors().exists()).toBe(true);
    });

    it('passes the correct error to the component', () => {
      expect(findSubscriptionActivationErrors().props('error')).toBe(CONNECTIVITY_ERROR);
    });
  });
});
