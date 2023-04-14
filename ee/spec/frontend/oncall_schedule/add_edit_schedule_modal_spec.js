import { GlModal, GlAlert } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import mockTimezones from 'test_fixtures/timezones/full.json';
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

  function updateSchedule(localWrapper) {
    localWrapper.findComponent(GlModal).vm.$emit('primary', { preventDefault: jest.fn() });
    return nextTick();
  }

  const createComponentWithApollo = ({
    updateHandler = jest.fn().mockResolvedValue(updateScheduleResponse),
  } = {}) => {
    localVue.use(VueApollo);
    updateScheduleHandler = updateHandler;

    const requestHandlers = [[updateOncallScheduleMutation, updateScheduleHandler]];

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

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModalForm = () => wrapper.findComponent(AddEditScheduleForm);

  const submitForm = () => findModal().vm.$emit('primary', { preventDefault: jest.fn() });

  const updatedName = 'Updated schedule name';
  const updatedTimezone = mockTimezones[0];
  const updatedDescription = 'Updated schedule description';

  const updateForm = () => {
    const emitUpdate = (args) => findModalForm().vm.$emit('update-schedule-form', args);

    emitUpdate({
      type: 'name',
      value: updatedName,
    });

    emitUpdate({
      type: 'description',
      value: updatedDescription,
    });

    emitUpdate({
      type: 'timezone',
      value: updatedTimezone,
    });
  };
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

    it('prevents form submit if schedule is invalid', () => {
      createComponent({
        modalId: addScheduleModalId,
        data: { form: { name: 'schedule', timezone: null } },
      });
      submitForm();
      expect(mutate).not.toHaveBeenCalled();
    });

    it("doesn't hide a modal and shows error alert on fail", async () => {
      const error = 'some error';
      mutate.mockImplementation(() => Promise.reject(error));
      updateForm();
      await nextTick();

      submitForm();
      await waitForPromises();
      const alert = findAlert();
      expect(mockHideModal).not.toHaveBeenCalled();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(error);
    });

    it('makes a request with form data to create a schedule and hides a modal', async () => {
      mutate.mockImplementation(() =>
        Promise.resolve({ data: { oncallScheduleCreate: { errors: [] } } }),
      );
      updateForm();
      await nextTick();
      submitForm();
      expect(mutate).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        update: expect.any(Function),
        variables: {
          oncallScheduleCreateInput: {
            projectPath,
            name: updatedName,
            description: updatedDescription,
            timezone: updatedTimezone.identifier,
          },
        },
      });
      await waitForPromises();
      expect(mockHideModal).toHaveBeenCalled();
    });

    it('should clear the schedule form on a successful creation', () => {
      mutate.mockImplementation(() =>
        Promise.resolve({ data: { oncallScheduleCreate: { errors: [] } } }),
      );
      submitForm();
      expect(findModalForm().props('form')).toMatchObject({
        name: undefined,
        description: undefined,
        timezone: undefined,
      });
    });

    it('should reset the form on modal cancel', async () => {
      updateForm();
      await nextTick();
      expect(findModalForm().props('form')).toMatchObject({
        name: updatedName,
        description: updatedDescription,
        timezone: updatedTimezone,
      });

      findModal().vm.$emit('canceled', { preventDefault: jest.fn() });
      await nextTick();
      expect(findModalForm().props('form')).toMatchObject({
        name: undefined,
        description: undefined,
        timezone: undefined,
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

    it("doesn't hide the modal on fail", async () => {
      const error = 'some error';
      mutate.mockRejectedValueOnce(error);
      submitForm();
      await waitForPromises();
      expect(mockHideModal).not.toHaveBeenCalled();
    });

    it('makes a request with `oncallScheduleUpdate` to update a schedule and hides a modal on successful update', async () => {
      mutate.mockResolvedValueOnce({ data: { oncallScheduleUpdate: { errors: [] } } });
      submitForm();

      expect(mutate).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        update: expect.any(Function),
        variables: {
          iid: mockSchedule.iid,
          projectPath,
          name: mockSchedule.name,
          description: mockSchedule.description,
          timezone: mockSchedule.timezone,
        },
      });
      await waitForPromises();
      expect(mockHideModal).toHaveBeenCalled();
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
        await waitForPromises();

        const alert = findAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain('Houston, we have a problem');
      });
    });

    describe('when the schedule timezone is updated', () => {
      useMockLocationHelper();

      it('should not reload the page if the timezone has not changed', async () => {
        mutate.mockResolvedValueOnce({ data: { oncallScheduleUpdate: { errors: [] } } });
        submitForm();
        await waitForPromises();
        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('should reload the page if the timezone has changed', async () => {
        mutate.mockResolvedValueOnce({ data: { oncallScheduleUpdate: { errors: [] } } });
        updateForm();
        await nextTick();
        submitForm();
        expect(mutate).toHaveBeenCalledWith({
          mutation: updateOncallScheduleMutation,
          update: expect.anything(),
          variables: {
            iid: mockSchedule.iid,
            projectPath,
            name: updatedName,
            description: updatedDescription,
            timezone: updatedTimezone.identifier,
          },
        });
        await waitForPromises();
        expect(window.location.reload).toHaveBeenCalled();
      });
    });

    it('should reset the form on modal cancel', async () => {
      updateForm();
      await nextTick();
      expect(findModalForm().props('form')).toMatchObject({
        name: updatedName,
        description: updatedDescription,
        timezone: updatedTimezone,
      });

      findModal().vm.$emit('canceled', { preventDefault: jest.fn() });
      await nextTick();
      expect(findModalForm().props('form')).toMatchObject({
        name: mockSchedule.name,
        description: mockSchedule.description,
        timezone: { identifier: mockSchedule.timezone },
      });
    });
  });
});
