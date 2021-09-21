import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SubscriptionActivationErrors from 'ee/admin/subscriptions/show/components/subscription_activation_errors.vue';
import SubscriptionActivationForm from 'ee/admin/subscriptions/show/components/subscription_activation_form.vue';
import SubscriptionActivationModal from 'ee/admin/subscriptions/show/components/subscription_activation_modal.vue';
import {
  activateSubscription,
  CONNECTIVITY_ERROR,
  SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
  subscriptionActivationInsertCode,
} from 'ee/admin/subscriptions/show/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { preventDefault } from '../../test_helpers';
import { activateLicenseMutationResponse } from '../mock_data';

describe('SubscriptionActivationModal', () => {
  let wrapper;

  const modalId = 'fake-modal-id';
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findSubscriptionActivationErrors = () =>
    wrapper.findComponent(SubscriptionActivationErrors);
  const findSubscriptionActivationForm = () => wrapper.findComponent(SubscriptionActivationForm);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(SubscriptionActivationModal, {
        propsData: {
          modalId,
          visible: false,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('idle state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has an id', () => {
      expect(findGlModal().attributes('modalid')).toBe(modalId);
    });

    it('shows a description text', () => {
      expect(wrapper.text()).toContain(subscriptionActivationInsertCode);
    });

    it('shows a title', () => {
      expect(findGlModal().attributes('title')).toBe(activateSubscription);
    });

    it('shows the subscription activation form', () => {
      expect(findSubscriptionActivationForm().exists()).toBe(true);
    });

    it('hides the form default button', () => {
      expect(findSubscriptionActivationForm().props('hideSubmitButton')).toBe(true);
    });

    it('does not show any error', () => {
      expect(findSubscriptionActivationErrors().exists()).toBe(false);
    });

    it('emits a change event', () => {
      expect(wrapper.emitted('change')).toBeUndefined();

      findGlModal().vm.$emit('change', false);

      expect(wrapper.emitted('change')).toEqual([[false]]);
    });
  });

  describe('subscription activation', () => {
    const fakeEvent = 'fake-modal-event';

    describe('when submitting the form', () => {
      beforeEach(() => {
        createComponent();
        jest
          .spyOn(wrapper.vm, 'handlePrimary')
          .mockImplementation(() => wrapper.vm.$emit(fakeEvent));
        findGlModal().vm.$emit('primary', { preventDefault });
      });

      it('emits the correct event', () => {
        expect(wrapper.emitted(fakeEvent)).toEqual([[]]);
      });
    });

    describe('successful activation', () => {
      beforeEach(() => {
        createComponent({ props: { visible: true } });
      });

      it('provides the correct prop to the modal', () => {
        expect(findGlModal().props('visible')).toBe(true);
      });

      it('hides the modal', () => {
        expect(wrapper.emitted('change')).toBeUndefined();

        findSubscriptionActivationForm().vm.$emit(
          SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
          activateLicenseMutationResponse.SUCCESS.data.gitlabSubscriptionActivate.license,
        );

        expect(wrapper.emitted('change')).toEqual([[false]]);
        expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT)).toEqual([
          [activateLicenseMutationResponse.SUCCESS.data.gitlabSubscriptionActivate.license],
        ]);
      });
    });

    describe('failing activation', () => {
      beforeEach(() => {
        createComponent();
        findSubscriptionActivationForm().vm.$emit(
          SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
          CONNECTIVITY_ERROR,
        );
      });

      it('passes the correct props', () => {
        expect(findSubscriptionActivationErrors().props('error')).toBe(CONNECTIVITY_ERROR);
      });

      it('resets the component state when closing', async () => {
        await findGlModal().vm.$emit('hidden');

        expect(findSubscriptionActivationErrors().exists()).toBe(false);
      });
    });
  });
});
