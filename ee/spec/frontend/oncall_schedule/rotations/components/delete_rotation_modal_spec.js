import { GlModal, GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import DeleteRotationModal, {
  i18n,
} from 'ee/oncall_schedules/components/rotations/components/delete_rotation_modal.vue';
import { deleteRotationModalId } from 'ee/oncall_schedules/constants';
import destroyOncallRotationMutation from 'ee/oncall_schedules/graphql/mutations/destroy_oncall_rotation.mutation.graphql';
import getOncallSchedulesQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getOncallSchedulesQueryResponse,
  destroyRotationResponse,
  destroyRotationResponseWithErrors,
} from '../../mocks/apollo_mock';
import mockRotations from '../../mocks/mock_rotation.json';

describe('DeleteRotationModal', () => {
  let wrapper;
  let mockApollo;
  let destroyRotationHandler;

  const projectPath = 'group/project';
  const mockHideModal = jest.fn(function hide() {
    this.$emit('hide');
  });
  const rotation = mockRotations[0];
  const schedule =
    getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalText = () => wrapper.findComponent(GlSprintf);
  const findAlert = () => wrapper.findComponent(GlAlert);

  function destroyRotation() {
    wrapper.findComponent(GlModal).vm.$emit('primary', { preventDefault: jest.fn() });
  }

  function createComponentWithApollo({
    destroyHandler = jest.fn().mockResolvedValue(destroyRotationResponse),
    props = {},
  } = {}) {
    Vue.use(VueApollo);
    destroyRotationHandler = destroyHandler;

    const requestHandlers = [
      [getOncallSchedulesQuery, jest.fn().mockResolvedValue(getOncallSchedulesQueryResponse)],
      [destroyOncallRotationMutation, destroyRotationHandler],
    ];

    mockApollo = createMockApollo(requestHandlers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getOncallSchedulesQuery,
      variables: {
        projectPath,
      },
      data: getOncallSchedulesQueryResponse.data,
    });

    wrapper = shallowMount(DeleteRotationModal, {
      apolloProvider: mockApollo,
      propsData: {
        rotation,
        modalId: deleteRotationModalId,
        schedule,
        ...props,
      },
      provide: {
        projectPath,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
          methods: {
            hide: mockHideModal,
          },
        }),
      },
    });
  }

  it('renders delete rotation modal layout', () => {
    createComponentWithApollo();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('renders delete modal with the correct rotation information', () => {
    it('renders name of rotation to destroy', () => {
      createComponentWithApollo();

      expect(findModalText().attributes('message')).toBe(i18n.deleteRotationMessage);
    });

    it('renders correct buttons for actions', () => {
      createComponentWithApollo();

      expect(findModal().props('actionCancel').text).toBe(i18n.cancel);
      expect(findModal().props('actionPrimary').text).toBe(i18n.deleteRotation);
      expect(findModal().props('actionPrimary').attributes).toEqual({
        category: 'primary',
        variant: 'danger',
        loading: false,
      });
    });
  });

  describe('Rotation destroy apollo API call', () => {
    it('has the name of the rotation to delete based on getOncallSchedulesQuery', async () => {
      createComponentWithApollo();

      await waitForPromises();
      expect(findModal().attributes('data-testid')).toBe(`delete-rotation-modal-${rotation.id}`);
    });

    it('calls a mutation with correct parameters and destroys a rotation', async () => {
      createComponentWithApollo();
      destroyRotation();
      await waitForPromises();

      expect(destroyRotationHandler).toHaveBeenCalled();
      expect(wrapper.emitted('rotation-deleted')).toBeDefined();
      expect(mockHideModal).toHaveBeenCalled();
    });

    describe('When Apollo mutation has a recoverable error', () => {
      beforeEach(async () => {
        createComponentWithApollo({
          destroyHandler: jest.fn().mockResolvedValue(destroyRotationResponseWithErrors),
        });
        destroyRotation();
        await waitForPromises();
      });

      it('does not hide the modal on fail and shows the alert if mutation had a recoverable error', () => {
        const alert = findAlert();
        expect(mockHideModal).not.toHaveBeenCalled();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain(
          destroyRotationResponseWithErrors.data.oncallRotationDestroy.errors[0],
        );
      });

      it('the error is cleared on alert dismissal', async () => {
        expect(wrapper.vm.error).toBe(
          destroyRotationResponseWithErrors.data.oncallRotationDestroy.errors[0],
        );

        findAlert().vm.$emit('dismiss', { preventDefault: jest.fn() });
        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});
