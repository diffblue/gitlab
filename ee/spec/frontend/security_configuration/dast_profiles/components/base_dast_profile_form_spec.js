import { GlAlert, GlForm, GlModal } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import merge from 'lodash/merge';
import VueApollo from 'vue-apollo';
import BaseDastProfileForm from 'ee/security_configuration/dast_profiles/components/base_dast_profile_form.vue';
import dastSiteProfileCreateMutation from 'ee/security_configuration/dast_profiles/dast_site_profiles/graphql/dast_site_profile_create.mutation.graphql';
import { dastSiteProfileCreate } from 'ee_jest/security_configuration/dast_profiles/dast_site_profiles/mock_data/apollo_mock';
import resolvers from 'ee/vue_shared/security_configuration/graphql/resolvers/resolvers';
import { typePolicies } from 'ee/vue_shared/security_configuration/graphql/provider';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

const mutationVariables = {
  foo: 'bar',
};

const defaultProps = {
  mutation: dastSiteProfileCreateMutation,
  mutationType: 'dastSiteProfileCreate',
  mutationVariables,
  modalProps: {},
};

describe('BaseDastProfileForm', () => {
  let wrapper;
  let requestHandler;

  // Finders
  const findForm = () => wrapper.findComponent(GlForm);
  const findHeader = () => wrapper.findByTestId('header');
  const findPolicyProfileAlert = () => wrapper.findByTestId('dast-policy-profile-alert');
  const findErrorAlert = () => wrapper.findByTestId('dast-profile-form-alert');
  const findCancelModal = () => wrapper.findByTestId('dast-profile-form-cancel-modal');
  const findCancelButton = () => wrapper.findByTestId('dast-profile-form-cancel-button');
  const findSubmitButton = () => wrapper.findByTestId('dast-profile-form-submit-button');

  // Helpers
  const submitForm = () => findForm().vm.$emit('submit', { preventDefault: () => {} });

  // Assertions
  const expectSubmitNotLoading = () => expect(findSubmitButton().props('loading')).toBe(false);

  const createComponent = (options) => {
    const apolloProvider = createMockApollo(
      [[dastSiteProfileCreateMutation, requestHandler]],
      resolvers,
      { typePolicies },
    );

    const mountOpts = merge(
      {},
      {
        propsData: defaultProps,
      },
      options,
      {
        apolloProvider,
      },
    );

    wrapper = shallowMountExtended(BaseDastProfileForm, mountOpts);
  };

  beforeEach(() => {
    // default request handler
    requestHandler = jest.fn().mockResolvedValue(dastSiteProfileCreate());
  });

  it('renders default slot', () => {
    const testId = 'default-slot-content';
    createComponent({
      slots: {
        default: `<div data-testid='${testId}' />`,
      },
    });

    expect(wrapper.findByTestId(testId).exists()).toBe(true);
  });

  describe('header', () => {
    const title = 'Page title';

    it('renders by default', () => {
      createComponent({
        slots: {
          title,
        },
      });

      const header = findHeader();
      expect(header.exists()).toBe(true);
      expect(header.text()).toBe(title);
    });

    it('does not render header if show-header is false', () => {
      createComponent({
        propsData: {
          showHeader: false,
        },
        slots: {
          title,
        },
      });

      expect(findHeader().exists()).toBe(false);
    });
  });

  describe('security policies', () => {
    it('does not render policy alert by default', () => {
      createComponent();

      expect(findPolicyProfileAlert().exists()).toBe(false);
    });

    describe('when profile comes from a policy', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            isPolicyProfile: true,
          },
        });
      });

      it('shows a policy alert', () => {
        expect(findPolicyProfileAlert().exists()).toBe(true);
      });

      it('disables submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(true);
      });
    });
  });

  describe('modal', () => {
    const modalProps = {
      title: 'Modal title',
    };

    beforeEach(() => {
      createComponent({
        propsData: {
          modalProps,
        },
      });
    });
  });

  describe('when submitting the form', () => {
    it('triggers GraphQL mutation', () => {
      createComponent();
      expect(requestHandler).not.toHaveBeenCalled();

      submitForm();

      expect(requestHandler).toHaveBeenCalledWith({
        input: mutationVariables,
      });
    });

    it('sets loading state', async () => {
      createComponent();

      expectSubmitNotLoading();

      submitForm();
      await nextTick();

      expect(findSubmitButton().props('loading')).toBe(true);
    });

    it('on success, emits success event', async () => {
      createComponent();

      expect(wrapper.emitted('success')).toBeUndefined();

      submitForm();
      await waitForPromises();

      expect(wrapper.emitted('success')).toHaveLength(1);
    });

    describe('when the API returns a top-level error', () => {
      const defaultErrorMessage = 'Default error message';

      beforeEach(async () => {
        requestHandler.mockRejectedValue(new Error('GraphQL Network Error'));
        createComponent({
          slots: {
            'error-message': defaultErrorMessage,
          },
        });
        submitForm();
        await waitForPromises();
      });

      it('resets loading state', () => {
        expectSubmitNotLoading();
      });

      it('shows an alert with the default error message', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findErrorAlert().text()).toBe(defaultErrorMessage);
      });
    });

    describe('when the API returns errors as data', () => {
      const errors = ['error#1', 'error#2', 'error#3'];

      beforeEach(async () => {
        requestHandler.mockResolvedValue(dastSiteProfileCreate(errors));
        createComponent({
          stubs: { GlAlert },
        });
        submitForm();
        await waitForPromises();
      });

      it('resets loading state', () => {
        expectSubmitNotLoading();
      });

      it('shows an alert with the returned errors', () => {
        const alert = findErrorAlert();
        expect(alert.exists()).toBe(true);
        errors.forEach((error) => {
          expect(alert.text()).toContain(error);
        });
      });
    });
  });

  describe('when cancelling the action', () => {
    describe('without changing the form', () => {
      beforeEach(() => {
        createComponent();
      });

      it('emits cancel event', () => {
        findCancelButton().vm.$emit('click');
        expect(wrapper.emitted('cancel')).toHaveLength(1);
      });
    });

    describe('after changing the form', () => {
      it('asks the user to confirm the action', async () => {
        createComponent({
          propsData: {
            formTouched: true,
          },
          stubs: { GlModal },
        });

        await waitForPromises();

        const toggleModalMock = jest.spyOn(resolvers.Mutation, 'toggleModal').mockReturnValue();
        findCancelButton().vm.$emit('click');

        await waitForPromises();

        expect(toggleModalMock).toHaveBeenCalled();
      });

      it('emits cancel event upon confirming', async () => {
        createComponent({
          propsData: {
            formTouched: false,
          },
          stubs: { GlModal },
        });
        await waitForPromises();

        findCancelModal().vm.$emit('primary');
        await waitForPromises();

        expect(wrapper.emitted('cancel')).toHaveLength(1);
      });
    });
  });
});
