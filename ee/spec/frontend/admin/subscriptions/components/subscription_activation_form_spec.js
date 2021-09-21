import { GlForm, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import SubscriptionActivationForm from 'ee/admin/subscriptions/show/components/subscription_activation_form.vue';
import {
  CONNECTIVITY_ERROR,
  INVALID_CODE_ERROR,
  SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
  subscriptionQueries,
} from 'ee/admin/subscriptions/show/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { preventDefault, stopPropagation } from '../../test_helpers';
import { activateLicenseMutationResponse } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('SubscriptionActivationForm', () => {
  let wrapper;

  const fakeActivationCodeTrimmed = 'aaasddfffdddas';
  const fakeActivationCode = `${fakeActivationCodeTrimmed}   `;

  const createMockApolloProvider = (resolverMock) => {
    localVue.use(VueApollo);
    return createMockApollo([[subscriptionQueries.mutation, resolverMock]]);
  };

  const findActivateButton = () => wrapper.findByTestId('activate-button');
  const findAgreementCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findAgreementCheckboxInput = () => findAgreementCheckbox().find('input');
  const findAgreementCheckboxFormGroupSpan = () =>
    wrapper.findByTestId('form-group-terms').find('span');
  const findActivationCodeFormGroup = () => wrapper.findByTestId('form-group-activation-code');
  const findActivationCodeInput = () => wrapper.findComponent(GlFormInput);
  const findActivateSubscriptionForm = () => wrapper.findComponent(GlForm);

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
        localVue,
        apolloProvider: createMockApolloProvider(mutationMock),
        propsData: {
          ...props,
        },
        stubs: {
          GlFormInput: GlFormInputStub,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
  });

  describe('form validation', () => {
    const mutationMock = jest.fn();
    beforeEach(async () => {
      createComponentWithApollo({ mutationMock, mountMethod: mount });
      await findAgreementCheckbox().vm.$emit('input', false);
      findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
    });

    it('shows an error for the text field', () => {
      expect(findActivationCodeFormGroup().text()).toContain('Please fill out this field.');
    });

    it('applies the correct class', () => {
      expect(findAgreementCheckboxFormGroupSpan().attributes('class')).toBe('');
    });

    it('does not perform any mutation', () => {
      expect(mutationMock).toHaveBeenCalledTimes(0);
    });
  });

  describe('activate the subscription', () => {
    describe('when submitting the mutation is successful', () => {
      const mutationMock = jest.fn().mockResolvedValue(activateLicenseMutationResponse.SUCCESS);
      beforeEach(async () => {
        createComponentWithApollo({ mutationMock, mountMethod: mount });
        jest.spyOn(wrapper.vm, 'updateSubscriptionAppCache').mockImplementation();
        await findActivationCodeInput().vm.$emit('input', fakeActivationCode);
        await findAgreementCheckboxInput().trigger('click');
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

      it('calls the method to update the cache', () => {
        expect(wrapper.vm.updateSubscriptionAppCache).toHaveBeenCalledTimes(1);
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
      const mutationMock = jest
        .fn()
        .mockResolvedValue(activateLicenseMutationResponse.CONNECTIVITY_ERROR);
      beforeEach(async () => {
        createComponentWithApollo({ mutationMock, mountMethod: mount });
        await findActivationCodeInput().vm.$emit('input', fakeActivationCode);
        await findAgreementCheckboxInput().trigger('click');
        findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
      });

      it('emits an failure event with a connectivity error payload', () => {
        expect(wrapper.emitted(SUBSCRIPTION_ACTIVATION_FAILURE_EVENT)).toEqual([
          [CONNECTIVITY_ERROR],
        ]);
      });
    });

    describe('when the mutation is not successful with invalid activation code error', () => {
      const mutationMock = jest
        .fn()
        .mockResolvedValue(activateLicenseMutationResponse.INVALID_CODE_ERROR);
      beforeEach(async () => {
        createComponentWithApollo({ mutationMock, mountMethod: mount });
        await findActivationCodeInput().vm.$emit('input', fakeActivationCode);
        await findAgreementCheckboxInput().trigger('click');
        findActivateSubscriptionForm().vm.$emit('submit', createFakeEvent());
      });

      it('emits an failure event with a connectivity error payload', () => {
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
