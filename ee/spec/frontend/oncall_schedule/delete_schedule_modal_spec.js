import { GlModal, GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import DeleteScheduleModal, {
  i18n,
} from 'ee/oncall_schedules/components/delete_schedule_modal.vue';
import { deleteScheduleModalId } from 'ee/oncall_schedules/components/oncall_schedule.vue';
import destroyOncallScheduleMutation from 'ee/oncall_schedules/graphql/mutations/destroy_oncall_schedule.mutation.graphql';
import getOncallSchedulesQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getOncallSchedulesQueryResponse,
  destroyScheduleResponse,
  destroyScheduleResponseWithErrors,
} from './mocks/apollo_mock';

const localVue = createLocalVue();
const projectPath = 'group/project';
const mutate = jest.fn();
const mockHideModal = jest.fn();
const schedule =
  getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];

describe('DeleteScheduleModal', () => {
  let wrapper;
  let fakeApollo;
  let destroyScheduleHandler;

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalText = () => wrapper.findComponent(GlSprintf);
  const findAlert = () => wrapper.findComponent(GlAlert);

  async function destroySchedule(localWrapper) {
    localWrapper.findComponent(GlModal).vm.$emit('primary', { preventDefault: jest.fn() });
  }

  const createComponent = ({ data = {}, props = {} } = {}) => {
    wrapper = shallowMount(DeleteScheduleModal, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        modalId: deleteScheduleModalId,
        schedule,
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
    wrapper.vm.$refs.deleteScheduleModal.hide = mockHideModal;
  };

  function createComponentWithApollo({
    destroyHandler = jest.fn().mockResolvedValue(destroyScheduleResponse),
  } = {}) {
    localVue.use(VueApollo);
    destroyScheduleHandler = destroyHandler;

    const requestHandlers = [
      [getOncallSchedulesQuery, jest.fn().mockResolvedValue(getOncallSchedulesQueryResponse)],
      [destroyOncallScheduleMutation, destroyScheduleHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getOncallSchedulesQuery,
      variables: {
        projectPath: 'group/project',
      },
      data: getOncallSchedulesQueryResponse.data,
    });

    wrapper = shallowMount(DeleteScheduleModal, {
      localVue,
      apolloProvider: fakeApollo,
      propsData: {
        schedule,
        modalId: deleteScheduleModalId,
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

  it('renders delete schedule modal layout', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('renders delete modal with the correct schedule information', () => {
    it('renders name of schedule to destroy', () => {
      expect(findModalText().attributes('message')).toBe(i18n.deleteScheduleMessage);
    });
  });

  describe('Schedule destroy apollo API call', () => {
    it('makes a request with `oncallScheduleDestroy` to delete a schedule', () => {
      mutate.mockResolvedValueOnce({});
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(mutate).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        update: expect.anything(),
        variables: { iid: '37', projectPath },
      });
    });

    it('hides the modal on successful schedule deletion', async () => {
      mutate.mockResolvedValueOnce({ data: { oncallScheduleDestroy: { errors: [] } } });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      expect(mockHideModal).toHaveBeenCalled();
    });

    it("doesn't hide the modal on deletion fail", async () => {
      const error = 'some error';
      mutate.mockResolvedValueOnce({ data: { oncallScheduleDestroy: { errors: [error] } } });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      const alert = findAlert();
      expect(mockHideModal).not.toHaveBeenCalled();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(error);
    });
  });

  describe('with mocked Apollo client', () => {
    it('has the name of the schedule to delete based on getOncallSchedulesQuery', async () => {
      createComponentWithApollo();

      await jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();

      expect(findModal().attributes('data-testid')).toBe(`delete-schedule-modal-${schedule.iid}`);
    });

    it('calls a mutation with correct parameters and destroys a schedule', async () => {
      createComponentWithApollo();

      await destroySchedule(wrapper);

      expect(destroyScheduleHandler).toHaveBeenCalled();
    });

    it('displays alert if mutation had a recoverable error', async () => {
      createComponentWithApollo({
        destroyHandler: jest.fn().mockResolvedValue(destroyScheduleResponseWithErrors),
      });

      await destroySchedule(wrapper);
      await waitForPromises();

      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain('Houston, we have a problem');
    });
  });
});
