import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';

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
import { preventDefault } from 'ee_jest/admin/test_helpers';
import { activateLicenseMutationResponse } from '../mock_data';

const modalId = 'fake-modal-id';

describe('SubscriptionActivationModal', () => {
  let wrapper;
  const submitSpy = jest.fn();

  const findGlModal = () => wrapper.findComponent(GlModal);
  const firePrimaryEvent = () => findGlModal().vm.$emit('primary', { preventDefault });
  const findSubscriptionActivationErrors = () =>
    wrapper.findComponent(SubscriptionActivationErrors);
  const findSubscriptionActivationForm = () => wrapper.findComponent(SubscriptionActivationForm);

  const createComponent = (options = {}) => {
    const { props = {} } = options;
    wrapper = shallowMount(SubscriptionActivationModal, {
      propsData: {
        modalId,
        visible: false,
        ...props,
      },
      stubs: {
        SubscriptionActivationForm: stubComponent(SubscriptionActivationForm, {
          methods: { submit: submitSpy },
        }),
      },
    });
  };

  afterEach(() => {
    submitSpy.mockClear();
  });

  describe('idle state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has an id', () => {
      expect(findGlModal().attributes('modalid')).toBe(modalId);
    });

    it('is size small', () => {
      expect(findGlModal().props('size')).toBe('sm');
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
    describe('when the "primary" button is clicked', () => {
      beforeEach(async () => {
        createComponent({ props: { visible: true } });
        await nextTick();
      });

      it('submits the form', () => {
        firePrimaryEvent();
        expect(submitSpy).toHaveBeenCalled();
      });

      it('shows loading in the button', async () => {
        firePrimaryEvent();
        // Wait for submit to emit event
        await nextTick();
        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(true);
      });

      it('shows loading in modal trigger', () => {
        firePrimaryEvent();
        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(false);
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
