import { GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import mockTimezones from 'test_fixtures/timezones/full.json';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import AddEditScheduleForm from 'ee/oncall_schedules/components/add_edit_schedule_form.vue';
import { stubComponent } from 'helpers/stub_component';
import { getOncallSchedulesQueryResponse } from './mocks/apollo_mock';

describe('AddEditScheduleForm', () => {
  let wrapper;
  const projectPath = 'group/project';
  const mutate = jest.fn();
  const mockSchedule =
    getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];

  const createComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = shallowMount(AddEditScheduleForm, {
      propsData: {
        form: {
          name: mockSchedule.name,
          description: mockSchedule.description,
          timezone: mockTimezones[0],
        },
        validationState: {
          name: true,
          timezone: true,
        },
        ...props,
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
      stubs,
    });
  };

  const findTimezoneDropdown = () => wrapper.findComponent(TimezoneDropdown);
  const findScheduleName = () => wrapper.findComponent(GlFormGroup);

  it('renders form layout', () => {
    createComponent({
      stubs: {
        TimezoneDropdown: stubComponent(TimezoneDropdown, {
          template: `<div />`,
        }),
      },
    });
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('isTimezoneSelected', () => {
    beforeEach(() => {
      createComponent({
        props: {
          form: { name: '', description: '', timezone: mockTimezones[0] },
        },
      });
    });

    it('returns true if a given timezone is selected within a form', () => {
      const isTimezoneSelected = wrapper.vm.isTimezoneSelected(mockTimezones[0]);

      expect(isTimezoneSelected).toEqual(true);
    });

    it('returns false if a different timezone is selected within a form', () => {
      const isTimezoneSelected = wrapper.vm.isTimezoneSelected(mockTimezones[1]);

      expect(isTimezoneSelected).toEqual(false);
    });
  });

  describe('setTimezone', () => {
    beforeEach(() => {
      wrapper.vm.setTimezone(mockTimezones[0]);
    });

    it('emits custom event upon timezone selection', () => {
      const emittedEvent = wrapper.emitted('update-schedule-form');
      expect(emittedEvent).toHaveLength(1);
      expect(emittedEvent[0][0]).toEqual({ type: 'timezone', value: mockTimezones[0] });
    });

    it('sets a value for selectedDropdownTimezone', () => {
      expect(wrapper.vm.selectedDropdownTimezone).toEqual(mockTimezones[0]);
    });
  });

  describe('Schedule form validation', () => {
    it('should show feedback for an invalid name input validation state', () => {
      createComponent({
        props: {
          validationState: { name: false },
        },
      });
      expect(findScheduleName().attributes('state')).toBeUndefined();
    });
  });

  describe('Form validation', () => {
    describe('Timezone select', () => {
      it('has a validation red border when timezone field is invalid', () => {
        createComponent({
          props: {
            schedule: null,
            form: { name: '', description: '', timezone: '' },
            validationState: { timezone: false },
          },
        });
        expect(findTimezoneDropdown().props('additionalClass')).toStrictEqual([
          { 'invalid-dropdown': true },
        ]);
      });

      it('does not have a validation red border when timezone field is valid', () => {
        createComponent({
          props: {
            validationState: { timezone: true },
          },
        });
        expect(findTimezoneDropdown().props('additionalClass')).toStrictEqual([
          { 'invalid-dropdown': false },
        ]);
      });
    });
  });
});
