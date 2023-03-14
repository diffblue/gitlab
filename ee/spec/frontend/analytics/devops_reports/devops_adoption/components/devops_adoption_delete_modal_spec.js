import { GlModal, GlSprintf, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import DevopsAdoptionDeleteModal from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_delete_modal.vue';
import disableDevopsAdoptionNamespaceMutation from 'ee/analytics/devops_reports/devops_adoption/graphql/mutations/disable_devops_adoption_namespace.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  genericDeleteErrorMessage,
  dataErrorMessage,
  devopsAdoptionNamespaceData,
} from '../mock_data';

Vue.use(VueApollo);

const mockEvent = { preventDefault: jest.fn() };
const mutate = jest.fn().mockResolvedValue({
  data: {
    disableDevopsAdoptionNamespace: {
      errors: [],
    },
  },
});
const mutateWithDataErrors = jest.fn().mockResolvedValue({
  data: {
    disableDevopsAdoptionNamespace: {
      errors: [dataErrorMessage],
    },
  },
});
const mutateLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
const mutateWithErrors = jest.fn().mockRejectedValue(genericDeleteErrorMessage);

const modalId = 'some-generated-id';

describe('DevopsAdoptionDeleteModal', () => {
  let wrapper;

  const createComponent = ({ deleteEnabledNamespacesSpy = mutate, props = {} } = {}) => {
    const mockApollo = createMockApollo([
      [disableDevopsAdoptionNamespaceMutation, deleteEnabledNamespacesSpy],
    ]);

    wrapper = shallowMount(DevopsAdoptionDeleteModal, {
      apolloProvider: mockApollo,
      propsData: {
        modalId,
        namespace: devopsAdoptionNamespaceData.nodes[0],
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const cancelButtonDisabledState = () => findModal().props('actionCancel').attributes.disabled;
  const actionButtonLoadingState = () => findModal().props('actionPrimary').attributes.loading;
  const findAlert = () => findModal().findComponent(GlAlert);

  describe('default display', () => {
    beforeEach(() => createComponent());

    it('contains the corrrect id', () => {
      const modal = findModal();

      expect(modal.exists()).toBe(true);
      expect(modal.props('modalId')).toBe(modalId);
    });

    it('displays the confirmation message', () => {
      const text = `Are you sure that you would like to remove ${devopsAdoptionNamespaceData.nodes[0].namespace.fullName} from the table?`;

      expect(findModal().text()).toBe(text);
    });

    it('does not display an error', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe.each`
    state        | action    | expected
    ${'opening'} | ${'show'} | ${true}
    ${'closing'} | ${'hide'} | ${false}
  `('$state the modal', ({ action, expected }) => {
    beforeEach(() => {
      createComponent();
      findModal().vm.$emit(action);
    });

    it(`emits trackModalOpenState as ${expected}`, () => {
      expect(wrapper.emitted('trackModalOpenState')).toStrictEqual([[expected]]);
    });
  });

  describe('submitting the form', () => {
    describe('while waiting for the mutation', () => {
      beforeEach(() => createComponent({ deleteEnabledNamespacesSpy: mutateLoading }));

      it('disables the cancel button', async () => {
        expect(cancelButtonDisabledState()).toBe(false);

        findModal().vm.$emit('primary', mockEvent);

        await nextTick();

        expect(cancelButtonDisabledState()).toBe(true);
      });

      it('sets the action button state to loading', async () => {
        expect(actionButtonLoadingState()).toBe(false);

        findModal().vm.$emit('primary', mockEvent);

        await nextTick();

        expect(actionButtonLoadingState()).toBe(true);
      });
    });

    describe('successful submission', () => {
      beforeEach(async () => {
        createComponent();

        wrapper.vm.$refs.modal.hide = jest.fn();

        findModal().vm.$emit('primary', mockEvent);
        await waitForPromises();
      });

      it('submits the correct request variables', () => {
        expect(mutate).toHaveBeenCalledWith({
          id: [devopsAdoptionNamespaceData.nodes[0].id],
        });
      });

      it('emits dNamespacesRemoved with the correct variables', () => {
        const [params] = wrapper.emitted().enabledNamespacesRemoved[0];

        expect(params).toStrictEqual([devopsAdoptionNamespaceData.nodes[0].id]);
      });

      it('closes the modal after a successful mutation', () => {
        expect(wrapper.vm.$refs.modal.hide).toHaveBeenCalled();
      });
    });

    describe('error handling', () => {
      it.each`
        errorType     | errorLocation  | mutationSpy             | message
        ${'generic'}  | ${'top level'} | ${mutateWithErrors}     | ${genericDeleteErrorMessage}
        ${'specific'} | ${'data'}      | ${mutateWithDataErrors} | ${dataErrorMessage}
      `(
        'displays a $errorType error if the mutation has a $errorLocation error',
        async ({ mutationSpy, message }) => {
          createComponent({ deleteEnabledNamespacesSpy: mutationSpy });

          findModal().vm.$emit('primary', mockEvent);

          await waitForPromises();

          const alert = findAlert();

          expect(alert.exists()).toBe(true);
          expect(alert.props('variant')).toBe('danger');
          expect(alert.text()).toBe(message);
        },
      );

      it('calls sentry on top level error', async () => {
        jest.spyOn(Sentry, 'captureException');

        createComponent({ deleteEnabledNamespacesSpy: mutateWithErrors });

        findModal().vm.$emit('primary', mockEvent);

        await waitForPromises();

        expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(
          genericDeleteErrorMessage,
        );
      });
    });
  });
});
