import { GlModal, GlAlert } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import AddEditScheduleForm from 'ee/oncall_schedules/components/add_edit_schedule_form.vue';
import AddEditScheduleModal, {
  i18n,
} from 'ee/oncall_schedules/components/add_edit_schedule_modal.vue';
import { editScheduleModalId } from 'ee/oncall_schedules/components/oncall_schedule.vue';
import { addScheduleModalId } from 'ee/oncall_schedules/components/oncall_schedules_wrapper.vue';
import updateOncallScheduleMutation from 'ee/oncall_schedules/graphql/mutations/update_oncall_schedule.mutation.graphql';
import getOncallSchedulesWithRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getOncallSchedulesQueryResponse,
  updateScheduleResponse,
  updateScheduleResponseWithErrors,
} from './mocks/apollo_mock';
import mockTimezones from './mocks/mock_timezones.json';

describe('AddScheduleModal', () => {
  let wrapper;
  let fakeApollo;
  const localVue = createLocalVue();
  const projectPath = 'group/project';
  const mutate = jest.fn();
  const mockHideModal = jest.fn();
  const mockSchedule =
    getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];
  let updateScheduleHandler;

  const createComponent = ({ schedule, isEditMode, modalId, data } = {}) => {
    wrapper = shallowMount(AddEditScheduleModal, {
      data() {
        return {
          form: mockSchedule,
          ...data,
        };
      },
      propsData: {
        modalId,
        schedule,
        isEditMode,
      },
      provide: {
        projectPath,
        timezones: mockTimezones,
      },
      mocks: {
        $apollo: {
          mutate,
        },
      },
    });

    wrapper.vm.$refs.addUpdateScheduleModal.hide = mockHideModal;
  };

  async function awaitApolloDomMock() {
    await wrapper.vm.$nextTick(); // kick off the DOM update
    await jest.runOnlyPendingTimers(); // kick off the mocked GQL stuff (promises)
    await wrapper.vm.$nextTick(); // kick off the DOM update for flash
  }

  async function updateSchedule(localWrapper) {
    localWrapper.findComponent(GlModal).vm.$emit('primary', { preventDefault: jest.fn() });
  }

  const createComponentWithApollo = ({
    updateHandler = jest.fn().mockResolvedValue(updateScheduleResponse),
  } = {}) => {
    localVue.use(VueApollo);
    updateScheduleHandler = updateHandler;

    const requestHandlers = [
      [
        getOncallSchedulesWithRotationsQuery,
        jest.fn().mockResolvedValue(getOncallSchedulesQueryResponse),
      ],
      [updateOncallScheduleMutation, updateScheduleHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getOncallSchedulesWithRotationsQuery,
      variables: {
        projectPath: 'group/project',
      },
      data: getOncallSchedulesQueryResponse.data,
    });

    wrapper = shallowMount(AddEditScheduleModal, {
      localVue,
      apolloProvider: fakeApollo,
      data() {
        return {
          form: mockSchedule,
        };
      },
      propsData: {
        modalId: editScheduleModalId,
        isEditMode: true,
        schedule: mockSchedule,
      },
      provide: {
        projectPath,
        timezones: mockTimezones,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModalForm = () => wrapper.findComponent(AddEditScheduleForm);

  describe('Schedule create', () => {
    beforeEach(() => {
      createComponent({ modalId: addScheduleModalId });
    });

    describe('renders create modal with the correct schedule information', () => {
      it('renders name of correct modal id', () => {
        expect(findModal().attributes('modalid')).toBe(addScheduleModalId);
      });

      it('renders modal title', () => {
        expect(findModal().attributes('title')).toBe(i18n.addSchedule);
      });
    });

    it('makes a request with form data to create a schedule', () => {
      mutate.mockResolvedValueOnce({});
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(mutate).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        update: expect.any(Function),
        variables: {
          oncallScheduleCreateInput: {
            projectPath,
            ...mockSchedule,
            timezone: mockSchedule.timezone.identifier,
          },
        },
      });
    });

    it('hides the modal on successful schedule creation', async () => {
      mutate.mockResolvedValueOnce({ data: { oncallScheduleCreate: { errors: [] } } });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      expect(mockHideModal).toHaveBeenCalled();
    });

    it("doesn't hide a modal and shows error alert on fail", async () => {
      const error = 'some error';
      mutate.mockResolvedValueOnce({ data: { oncallScheduleCreate: { errors: [error] } } });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      const alert = findAlert();
      expect(mockHideModal).not.toHaveBeenCalled();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(error);
    });

    it('should clear the schedule form on a successful creation', () => {
      mutate.mockResolvedValueOnce({});
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(findModalForm().props('form')).toMatchObject({
        name: '',
        description: '',
        timezone: {},
      });
    });
  });

  describe('Schedule update', () => {
    beforeEach(() => {
      createComponent({ schedule: mockSchedule, isEditMode: true, modalId: editScheduleModalId });
    });

    describe('renders update modal with the correct schedule information', () => {
      it('renders name of correct modal id', () => {
        expect(findModal().attributes('modalid')).toBe(editScheduleModalId);
      });

      it('renders modal title', () => {
        expect(findModal().attributes('title')).toBe(i18n.editSchedule);
      });
    });

    describe('Schedule update apollo API call', () => {
      it('makes a request with `oncallScheduleUpdate` to update a schedule', () => {
        mutate.mockResolvedValueOnce({});
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        expect(mutate).toHaveBeenCalledWith({
          mutation: expect.any(Object),
          update: expect.anything(),
          variables: {
            iid: mockSchedule.iid,
            projectPath,
            name: mockSchedule.name,
            description: mockSchedule.description,
            timezone: mockSchedule.timezone.identifier,
          },
        });
      });

      it('hides the modal on successful schedule creation', async () => {
        mutate.mockResolvedValueOnce({ data: { oncallScheduleUpdate: { errors: [] } } });
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();
        expect(mockHideModal).toHaveBeenCalled();
      });

      it("doesn't hide the modal on fail", async () => {
        const error = 'some error';
        mutate.mockResolvedValueOnce({ data: { oncallScheduleUpdate: { errors: [error] } } });
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();
        expect(mockHideModal).not.toHaveBeenCalled();
      });
    });

    describe('with mocked Apollo client', () => {
      it('calls a mutation with correct parameters and updates a schedule', async () => {
        createComponentWithApollo();

        await updateSchedule(wrapper);

        expect(updateScheduleHandler).toHaveBeenCalled();
      });

      it('displays alert if mutation had a recoverable error', async () => {
        createComponentWithApollo({
          updateHandler: jest.fn().mockResolvedValue(updateScheduleResponseWithErrors),
        });

        await updateSchedule(wrapper);
        await awaitApolloDomMock();

        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain('Houston, we have a problem');
      });
    });

    describe('when the schedule timezone is updated', () => {
      useMockLocationHelper();

      it('it should not reload the page if the timezone has not changed', async () => {
        mutate.mockResolvedValueOnce({});
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('it should reload the page if the timezone has changed', async () => {
        createComponent({
          data: { form: { ...mockSchedule, timezone: mockTimezones[1] } },
          schedule: mockSchedule,
          isEditMode: true,
          modalId: editScheduleModalId,
        });
        mutate.mockResolvedValueOnce({});
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        expect(mutate).toHaveBeenCalledWith({
          mutation: updateOncallScheduleMutation,
          update: expect.anything(),
          variables: {
            iid: mockSchedule.iid,
            projectPath,
            name: mockSchedule.name,
            description: mockSchedule.description,
            timezone: mockTimezones[1].identifier,
          },
        });
        await waitForPromises();
        expect(window.location.reload).toHaveBeenCalled();
      });
    });
  });
});
