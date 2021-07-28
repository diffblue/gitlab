import { GlModal, GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
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

const localVue = createLocalVue();
const projectPath = 'group/project';
const mutate = jest.fn();
const mockHideModal = jest.fn();
const rotation = mockRotations[0];
const schedule =
  getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];

describe('DeleteRotationModal', () => {
  let wrapper;
  let fakeApollo;
  let destroyRotationHandler;

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalText = () => wrapper.findComponent(GlSprintf);
  const findAlert = () => wrapper.findComponent(GlAlert);

  async function awaitApolloDomMock() {
    await wrapper.vm.$nextTick(); // kick off the DOM update
    await jest.runOnlyPendingTimers(); // kick off the mocked GQL stuff (promises)
    await wrapper.vm.$nextTick(); // kick off the DOM update
  }

  async function destroyRotation(localWrapper) {
    localWrapper.findComponent(GlModal).vm.$emit('primary', { preventDefault: jest.fn() });
  }

  const createComponent = ({ data = {}, props = {} } = {}) => {
    wrapper = shallowMount(DeleteRotationModal, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        modalId: deleteRotationModalId,
        schedule,
        rotation,
        ...props,
      },
      provide: {
        projectPath,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
      stubs: { GlSprintf: false },
    });
    wrapper.vm.$refs.deleteRotationModal.hide = mockHideModal;
  };

  function createComponentWithApollo({
    destroyHandler = jest.fn().mockResolvedValue(destroyRotationResponse),
  } = {}) {
    localVue.use(VueApollo);
    destroyRotationHandler = destroyHandler;

    const requestHandlers = [
      [getOncallSchedulesQuery, jest.fn().mockResolvedValue(getOncallSchedulesQueryResponse)],
      [destroyOncallRotationMutation, destroyRotationHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getOncallSchedulesQuery,
      variables: {
        projectPath: 'group/project',
      },
      data: getOncallSchedulesQueryResponse.data,
    });

    wrapper = shallowMount(DeleteRotationModal, {
      localVue,
      apolloProvider: fakeApollo,
      propsData: {
        rotation,
        modalId: deleteRotationModalId,
        schedule,
      },
      provide: {
        projectPath,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders delete rotation modal layout', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('renders delete modal with the correct rotation information', () => {
    it('renders name of rotation to destroy', () => {
      expect(findModalText().attributes('message')).toBe(i18n.deleteRotationMessage);
    });
  });

  describe('Rotation destroy apollo API call', () => {
    it('makes a request with `oncallRotationDestroy` to delete a rotation', () => {
      mutate.mockResolvedValueOnce({});
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(mutate).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        update: expect.anything(),
        variables: { id: rotation.id, projectPath, scheduleIid: schedule.iid },
      });
    });

    it('hides the modal and emits the events on successful rotation deletion', async () => {
      expect(wrapper.emitted('rotation-deleted')).toBeUndefined();
      mutate.mockResolvedValueOnce({ data: { oncallRotationDestroy: { errors: [] } } });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      expect(mockHideModal).toHaveBeenCalled();
      expect(wrapper.emitted('rotation-deleted')).toHaveLength(1);
    });

    it('does not hide the modal on deletion fail and shows the error alert', async () => {
      const error = 'some error';
      mutate.mockResolvedValueOnce({ data: { oncallRotationDestroy: { errors: [error] } } });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      const alert = findAlert();
      expect(mockHideModal).not.toHaveBeenCalled();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(error);
    });
  });

  describe('with mocked Apollo client', () => {
    it('has the name of the rotation to delete based on getOncallSchedulesQuery', async () => {
      createComponentWithApollo();

      await jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();

      expect(findModal().attributes('data-testid')).toBe(`delete-rotation-modal-${rotation.id}`);
    });

    it('calls a mutation with correct parameters and destroys a rotation', async () => {
      createComponentWithApollo();

      await destroyRotation(wrapper);

      expect(destroyRotationHandler).toHaveBeenCalled();
    });

    it('displays alert if mutation had a recoverable error', async () => {
      createComponentWithApollo({
        destroyHandler: jest.fn().mockResolvedValue(destroyRotationResponseWithErrors),
      });

      await destroyRotation(wrapper);
      await awaitApolloDomMock();

      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain('Houston, we have a problem');
    });
  });
});
