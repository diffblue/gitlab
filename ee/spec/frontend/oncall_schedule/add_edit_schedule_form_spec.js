import { GlSearchBoxByType, GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import mockTimezones from 'test_fixtures/timezones/full.json';
import AddEditScheduleForm, {
  i18n,
} from 'ee/oncall_schedules/components/add_edit_schedule_form.vue';
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

  afterEach(() => {
    wrapper.destroy();
  });

  const findTimezoneDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownOptions = () => wrapper.findAllComponents(GlDropdownItem);
  const findTimezoneSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findScheduleName = () => wrapper.findComponent(GlFormGroup);

  it('renders form layout', () => {
    createComponent({
      stubs: {
        GlDropdown: stubComponent(GlDropdown, {
          template: `<div />`,
        }),
      },
    });
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('Schedule form validation', () => {
    it('should show feedback for an invalid name input validation state', async () => {
      createComponent({
        props: {
          validationState: { name: false },
        },
      });
      expect(findScheduleName().attributes('state')).toBeFalsy();
    });
  });

  describe('Timezone select', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has options based on provided BE data', () => {
      expect(findDropdownOptions()).toHaveLength(mockTimezones.length);
    });

    it('formats each option', () => {
      findDropdownOptions().wrappers.forEach((option, index) => {
        const tz = mockTimezones[index];
        const expectedValue = `(UTC ${tz.formatted_offset}) ${tz.abbr} ${tz.name}`;
        expect(option.text()).toBe(expectedValue);
      });
    });

    describe('timezones filtering', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should filter options based on search term', async () => {
        const searchTerm = 'Pacific';
        findTimezoneSearchBox().vm.$emit('input', searchTerm);
        await nextTick();
        const options = findDropdownOptions();
        expect(options).toHaveLength(1);
        expect(options.at(0).text()).toContain(searchTerm);
      });

      it('should display no results item when there are no filter matches', async () => {
        const searchTerm = 'someUnexistentTZ';
        findTimezoneSearchBox().vm.$emit('input', searchTerm);
        await nextTick();
        const options = findDropdownOptions();
        expect(options).toHaveLength(1);
        expect(options.at(0).text()).toContain(i18n.noResults);
      });
    });

    it('should add a checkmark to the selected option', async () => {
      const selectedTZOption = findDropdownOptions().at(0);
      selectedTZOption.vm.$emit('click');
      await nextTick();
      expect(selectedTZOption.attributes('ischecked')).toBe('true');
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
        expect(findTimezoneDropdown().classes()).toContain('invalid-dropdown');
      });

      it('does not have a validation red border when timezone field is valid', async () => {
        createComponent({
          props: {
            validationState: { timezone: true },
          },
        });
        expect(findTimezoneDropdown().classes()).not.toContain('invalid-dropdown');
      });
    });
  });
});
