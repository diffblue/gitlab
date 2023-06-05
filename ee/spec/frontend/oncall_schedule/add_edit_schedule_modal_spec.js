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
import createOncallScheduleMutation from 'ee/oncall_schedules/graphql/mutations/create_oncall_schedule.mutation.graphql';
import updateOncallScheduleMutation from 'ee/oncall_schedules/graphql/mutations/update_oncall_schedule.mutation.graphql';
import getOncallSchedulesWithRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import {
  getOncallSchedulesQueryResponse,
  updateScheduleResponse,
  createScheduleResponse,
  updateScheduleResponseWithErrors,
} from './mocks/apollo_mock';

describe('AddScheduleModal', () => {
  let wrapper;
  let mockApollo;
  let scheduleHandler;

  const mockSchedule =
    getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];
  const updatedName = 'Updated schedule name';
  const updatedTimezone = mockTimezones[0];
  const updatedDescription = 'Updated schedule description';
  const projectPath = 'group/project';

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModalForm = () => wrapper.findComponent(AddEditScheduleForm);

  const localVue = createLocalVue();
  const mockHideModal = jest.fn(function hide() {
    this.$emit('hide');
  });

  const submitForm = async () => {
    findModal().vm.$emit('primary', { preventDefault: jest.fn() });
    await nextTick;
    await waitForPromises();
  };

  const updateScheduleForm = ({ type, value }) => {
    return findModalForm().vm.$emit('update-schedule-form', {
      type,
      value,
    });
  };

  const updateAllFormFields = () => {
    updateScheduleForm({
      type: 'name',
      value: updatedName,
    });

    updateScheduleForm({
      type: 'description',
      value: updatedDescription,
    });

    updateScheduleForm({
      type: 'timezone',
      value: updatedTimezone,
    });
  };

  const createComponent = ({
    updateHandler = jest.fn().mockResolvedValue(createScheduleResponse),
    props = {},
  } = {}) => {
    localVue.use(VueApollo);
    scheduleHandler = updateHandler;

    const requestHandlers = [
      [createOncallScheduleMutation, scheduleHandler],
      [updateOncallScheduleMutation, scheduleHandler],
    ];

    mockApollo = createMockApollo(requestHandlers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getOncallSchedulesWithRotationsQuery,
      variables: {
        projectPath,
      },
      data: getOncallSchedulesQueryResponse.data,
    });

    wrapper = shallowMount(AddEditScheduleModal, {
      localVue,
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
      provide: {
        projectPath,
        timezones: mockTimezones,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            hide: mockHideModal,
          },
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  describe('Schedule create', () => {
    beforeEach(() => {
      createComponent({ props: { modalId: addScheduleModalId } });
    });

    describe('renders create modal with the correct schedule information', () => {
      it('renders name of correct modal id', () => {
        expect(findModal().props('modalId')).toBe(addScheduleModalId);
      });

      it('renders modal title', () => {
        expect(findModal().props('title')).toBe(i18n.addSchedule);
      });
    });

    it('prevents form submit if schedule is invalid', async () => {
      updateScheduleForm({ name: 'schedule' });
      await submitForm();

      expect(findModalForm().props('validationState').timezone).toBe(false);
    });

    it('should reset the form on modal cancel', async () => {
      updateAllFormFields();
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

    it('displays alert if mutation had a recoverable error', async () => {
      createComponent({
        updateHandler: jest.fn().mockResolvedValue(updateScheduleResponseWithErrors),
        props: { modalId: editScheduleModalId },
      });

      updateAllFormFields();
      await submitForm();

      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(
        updateScheduleResponseWithErrors.data.oncallScheduleUpdate.errors[0],
      );
      expect(mockHideModal).not.toHaveBeenCalled();
    });

    it('calls a mutation with correct parameters and creates a schedule', async () => {
      updateAllFormFields();
      await submitForm();

      expect(scheduleHandler).toHaveBeenCalled();
      expect(wrapper.emitted('scheduleCreated')).toBeDefined();
    });

    it('should clear the schedule form on a successful creation', async () => {
      updateAllFormFields();
      await submitForm();

      expect(findModalForm().props('form')).toMatchObject({
        name: undefined,
        description: undefined,
        timezone: undefined,
      });
    });
  });

  describe('Schedule update', () => {
    beforeEach(() => {
      createComponent({
        updateHandler: jest.fn().mockResolvedValue(updateScheduleResponse),
        props: { modalId: editScheduleModalId, schedule: mockSchedule, isEditMode: true },
      });
    });

    it('makes a request with to update a schedule and hides a modal on successful update', async () => {
      updateAllFormFields();
      await submitForm();

      expect(findModalForm().props('form')).toMatchObject({
        name: updatedName,
        description: updatedDescription,
        timezone: updatedTimezone,
      });
      expect(scheduleHandler).toHaveBeenCalled();
      expect(mockHideModal).toHaveBeenCalled();
    });

    it('displays alert if mutation had a recoverable error', async () => {
      createComponent({
        updateHandler: jest.fn().mockResolvedValue(updateScheduleResponseWithErrors),
        props: { modalId: editScheduleModalId, schedule: mockSchedule, isEditMode: true },
      });
      await submitForm();

      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain('Houston, we have a problem');
      expect(mockHideModal).not.toHaveBeenCalled();
    });

    it('should reset the form on modal cancel', async () => {
      updateAllFormFields();

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

    describe('when the schedule timezone is updated', () => {
      useMockLocationHelper();

      it('should not reload the page if the timezone has not changed', async () => {
        await submitForm();

        expect(window.location.reload).not.toHaveBeenCalled();
      });

      it('should reload the page if the timezone has changed', async () => {
        updateAllFormFields();
        await submitForm();

        expect(window.location.reload).toHaveBeenCalled();
      });
    });
  });
});
