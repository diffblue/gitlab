import { GlForm, GlFormCheckbox, GlFormInput, GlLink, GlSprintf } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import SubscriptionActivationForm from 'ee/admin/subscriptions/show/components/subscription_activation_form.vue';
import {
  CONNECTIVITY_ERROR,
  INVALID_CODE_ERROR,
  SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
  SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT,
  subscriptionActivationForm,
} from 'ee/admin/subscriptions/show/constants';
import activateSubscriptionMutation from 'ee/admin/subscriptions/show/graphql/mutations/activate_subscription.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { preventDefault, stopPropagation } from 'ee_jest/admin/test_helpers';
import {
  activateLicenseMutationResponse,
  fakeActivationCodeTrimmed,
  fakeActivationCode,
} from '../mock_data';

Vue.use(VueApollo);

describe('SubscriptionActivationForm', () => {
  let wrapper;

  const createMockApolloProvider = (resolverMock) => {
    return createMockApollo([[activateSubscriptionMutation, resolverMock]]);
  };

  const findActivateButton = () => wrapper.findByTestId('activate-button');
  const findAgreementCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findAgreementCheckboxFormGroup = () => wrapper.findByTestId('form-group-terms');
  const findAgreementCheckboxFormGroupSpan = () => findAgreementCheckboxFormGroup().find('span');
  const findActivationCodeFormGroup = () => wrapper.findByTestId('form-group-activation-code');
  const findActivationCodeInput = () => wrapper.findComponent(GlFormInput);
  const findActivateSubscriptionForm = () => wrapper.findComponent(GlForm);
  const findTermLink = () => findAgreementCheckboxFormGroup().findComponent(GlLink);

  const GlFormInputStub = stubComponent(GlFormInput, {
    template: `<input />`,
  });

  const createFakeEvent = () => ({ preventDefault, stopPropagation });
  const createComponentWithApollo = ({
    props = {},
    mutationMock,
    mountMethod = shallowMount,
  } = {}) => {
    wrapper = extendedWrapper(
      mountMethod(SubscriptionActivationForm, {
        apolloProvider: createMockApolloProvider(mutationMock),
        propsData: {
          ...props,
        },
        stubs: {
          GlFormInput: GlFormInputStub,
          GlSprintf,
        },
      }),
    );
  };

  describe('component setup', () => {
    beforeEach(() => createComponentWithApollo());

    it('presents a form', () => {
      expect(findActivateSubscriptionForm().exists()).toBe(true);
    });

    it('has an input', () => {
      expect(findActivationCodeInput().exists()).toBe(true);
    });

    it('applies a class to the checkbox', () => {
      expect(findAgreementCheckboxFormGroupSpan().attributes('class')).toBe('gl-text-gray-900!');
    });

    it('has an `Activate` button', () => {
      expect(findActivateButton().text()).toBe('Activate');
    });

    it('has a checkbox to accept subscription agreement', () => {
      expect(findAgreementCheckbox().exists()).toBe(true);
    });

    it('has the activate button enabled', () => {
      expect(findActivateButton().props('disabled')).toBe(false);
    });

    it('verify terms link url', () => {
      const link = findTermLink();
      expect(link.attributes('href')).toMatch(/https:\/\/about.gitlab.(com|cn)\/terms\//);
    });
  });

  describe('form validation', () => {
    const mutationMock = jest.fn().mockRejectedValue({});
    beforeEach(async () => {
      createComponentWithApollo({ mutationMock, mountMethod: mount });
      await findAgreementCheckbox().find('input').setChecked(false);
      findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
    });

    it('shows the help text field', () => {
      expect(findActivationCodeFormGroup().text()).toContain(
        subscriptionActivationForm.activationCodeFeedback,
      );
    });

    it('applies the correct class and shows help text field', () => {
      expect(findAgreementCheckboxFormGroupSpan().attributes('class')).toBe('');
      expect(findAgreementCheckboxFormGroup().text()).toContain(
        subscriptionActivationForm.acceptTermsFeedback,
      );
    });

    it('does not perform any mutation', () => {
      expect(mutationMock).toHaveBeenCalledTimes(0);
    });

    it(`emits the ${SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT} event`, () => {
      expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT).length).toBe(1);
    });

    describe('adds text that does not match the pattern', () => {
      beforeEach(async () => {
        await findActivationCodeInput().vm.$emit('input', `${fakeActivationCode}2021-asdf`);
      });

      it('shows the help text field', () => {
        expect(findActivationCodeFormGroup().text()).toContain(
          subscriptionActivationForm.activationCodeFeedback,
        );
      });

      describe('corrects fields to be valid', () => {
        beforeEach(async () => {
          await findActivationCodeInput().vm.$emit('input', fakeActivationCode);
          await findAgreementCheckbox().find('input').setChecked(true);
        });

        it('hides the help text field', () => {
          expect(findActivationCodeFormGroup().text()).not.toContain(
            subscriptionActivationForm.activationCodeFeedback,
          );
        });

        it('updates the validation class and hides help text field', () => {
          expect(findAgreementCheckboxFormGroupSpan().attributes('class')).toBe(
            'gl-text-gray-900!',
          );
          expect(findAgreementCheckboxFormGroup().text()).not.toContain(
            subscriptionActivationForm.acceptTermsFeedback,
          );
        });

        it(`emits the ${SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT} event`, async () => {
          findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
          await waitForPromises();
          expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_FINALIZED_EVENT).length).toBe(2);
        });
      });
    });
  });

  describe('activate the subscription', () => {
    describe('when submitting the mutation is successful', () => {
      const mutationMock = jest.fn().mockResolvedValue(activateLicenseMutationResponse.SUCCESS);

      beforeEach(async () => {
        createComponentWithApollo({ mutationMock, mountMethod: mount });
        await findActivationCodeInput().vm.$emit('input', fakeActivationCode);
        await findAgreementCheckbox().find('input').setChecked(true);
        findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
      });

      it('prevents default submit', () => {
        expect(preventDefault).toHaveBeenCalled();
      });

      it('calls mutate with the correct variables', () => {
        expect(mutationMock).toHaveBeenCalledWith({
          gitlabSubscriptionActivateInput: {
            activationCode: fakeActivationCodeTrimmed,
          },
        });
      });

      it('emits a successful event', () => {
        expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT)).toEqual([
          [activateLicenseMutationResponse.SUCCESS.data.gitlabSubscriptionActivate.license],
        ]);
      });
    });

    describe('when the mutation is not successful', () => {
      const mutationMock = jest
        .fn()
        .mockResolvedValue(activateLicenseMutationResponse.ERRORS_AS_DATA);
      beforeEach(() => {
        createComponentWithApollo({ mutationMock });
        findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
      });

      it('emits a unsuccessful event', () => {
        expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT)).toBeUndefined();
      });
    });

    describe('when the mutation is not successful with connectivity error', () => {
      it('emits an failure event with a connectivity error payload', async () => {
        const mutationMock = jest
          .fn()
          .mockResolvedValue(activateLicenseMutationResponse.CONNECTIVITY_ERROR);
        createComponentWithApollo({ mutationMock, mountMethod: mount });
        await findActivationCodeInput().vm.$emit('input', fakeActivationCode);
        await findAgreementCheckbox().find('input').setChecked(true);
        findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
        await waitForPromises();

        expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT)).toEqual([
          [CONNECTIVITY_ERROR],
        ]);
      });
    });

    describe('when the mutation is not successful with invalid activation code error', () => {
      it('emits an failure event with a connectivity error payload', async () => {
        const mutationMock = jest
          .fn()
          .mockResolvedValue(activateLicenseMutationResponse.INVALID_CODE_ERROR);
        createComponentWithApollo({ mutationMock, mountMethod: mount });
        await findActivationCodeInput().vm.$emit('input', fakeActivationCode);
        await findAgreementCheckbox().find('input').setChecked(true);
        findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
        await waitForPromises();

        expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT)).toEqual([
          [INVALID_CODE_ERROR],
        ]);
      });
    });

    describe('when the mutation request fails', () => {
      const mutationMock = jest.fn().mockRejectedValue(activateLicenseMutationResponse.FAILURE);
      beforeEach(() => {
        createComponentWithApollo({ mutationMock });
        findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
      });

      it('emits a unsuccessful event', () => {
        expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT)).toBeUndefined();
      });
    });
  });
});
