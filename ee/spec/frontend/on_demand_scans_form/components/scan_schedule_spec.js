import { GlDatepicker, GlFormGroup, GlToggle } from '@gitlab/ui';
import { merge } from 'lodash';
import { nextTick } from 'vue';
import mockTimezones from 'test_fixtures/timezones/full.json';
import ScanSchedule from 'ee/on_demand_scans_form/components/scan_schedule.vue';
import { SCAN_CADENCE_OPTIONS } from 'ee/on_demand_scans_form/settings';
import DropdownInput from 'ee/security_configuration/components/dropdown_input.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';

const timezoneSST = mockTimezones[2];

describe('ScanSchedule', () => {
  let wrapper;

  // Finders
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findProfileScheduleFormGroup = () => wrapper.findByTestId('profile-schedule-form-group');
  const findTimezoneDropdown = () => wrapper.findComponent(TimezoneDropdown);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findTimeInput = () => wrapper.find('input[type="time"]');
  const findCadenceInput = () => wrapper.findComponent(DropdownInput);

  // Helpers
  const setTimeInputValue = async (value) => {
    const input = findTimeInput();
    input.element.value = value;
    input.trigger('input');
    await nextTick();
  };

  const createComponent = (options = {}) => {
    wrapper = shallowMountExtended(
      ScanSchedule,
      merge(
        {
          provide: {
            timezones: mockTimezones,
          },
          stubs: {
            GlFormGroup: stubComponent(GlFormGroup, {
              props: ['disabled'],
            }),
            GlToggle: stubComponent(GlToggle, {
              props: ['value'],
            }),
            TimezoneDropdown: stubComponent(TimezoneDropdown, {
              props: ['disabled', 'timezoneData', 'value'],
            }),
          },
        },
        options,
      ),
    );
  };

  describe('default state', () => {
    beforeEach(() => {
      createComponent();
    });

    it('by default, checkbox is unchecked and fields are hidden', () => {
      expect(findToggle().props('value')).toBe(false);
      expect(findProfileScheduleFormGroup().exists()).toBe(false);
      expect(findTimezoneDropdown().exists()).toBe(false);
      expect(findCadenceInput().exists()).toBe(false);
    });

    it('initializes timezone dropdown properly', async () => {
      findToggle().vm.$emit('change', true);
      await nextTick();

      const timezoneDropdown = findTimezoneDropdown();

      expect(timezoneDropdown.props('timezoneData')).toEqual(mockTimezones);
      expect(timezoneDropdown.props('value')).toBe('');
    });
  });

  describe('once schedule is activated', () => {
    beforeEach(() => {
      createComponent();
      findToggle().vm.$emit('change', true);
    });

    it('shows fields', () => {
      expect(findTimezoneDropdown().exists()).toBe(true);
      expect(findProfileScheduleFormGroup().exists()).toBe(true);
      expect(findTimezoneDropdown().exists()).toBe(true);
      expect(findCadenceInput().exists()).toBe(true);
    });

    it('emits input payload', () => {
      expect(wrapper.emitted().input).toHaveLength(1);
      expect(wrapper.emitted().input[0]).toEqual([
        {
          active: true,
          cadence: {},
          startsAt: null,
          timezone: null,
        },
      ]);
    });

    it('computes start date when datepicker and time input are changed', async () => {
      findDatepicker().vm.$emit('input', new Date('2021-08-12'));
      await setTimeInputValue('11:00');

      expect(wrapper.emitted().input).toHaveLength(3);
      expect(wrapper.emitted().input[2]).toEqual([
        {
          active: true,
          cadence: {},
          startsAt: '2021-08-12T11:00:00.000Z',
          timezone: null,
        },
      ]);
    });

    it('nullyfies start date if date is invalid', async () => {
      findDatepicker().vm.$emit('input', new Date('2021-08-12'));
      await setTimeInputValue('');

      expect(wrapper.emitted().input).toHaveLength(3);
      expect(wrapper.emitted().input[2]).toEqual([
        {
          active: true,
          cadence: {},
          startsAt: null,
          timezone: null,
        },
      ]);
    });

    it('emits computed cadence value', async () => {
      findCadenceInput().vm.$emit('input', SCAN_CADENCE_OPTIONS[5].value);
      await nextTick();

      expect(wrapper.emitted().input[1][0].cadence).toEqual({ unit: 'MONTH', duration: 6 });
    });

    it('deactives schedule when checkbox is unchecked', async () => {
      findToggle().vm.$emit('change', false);
      await nextTick();

      expect(wrapper.emitted().input).toHaveLength(2);
      expect(wrapper.emitted().input[1]).toEqual([
        {
          active: false,
          cadence: {},
          startsAt: null,
          timezone: null,
        },
      ]);
    });
  });

  describe('editing a schedule', () => {
    const schedule = {
      active: true,
      startsAt: '2001-09-27T08:45:00.000Z',
      cadence: { unit: 'MONTH', duration: 1 },
      timezone: timezoneSST.identifier,
    };

    it('initializes fields with provided values', () => {
      createComponent({
        propsData: {
          value: {
            ...schedule,
            cadence: { unit: 'MONTH', duration: 1 },
          },
        },
      });

      expect(findToggle().props('value')).toBe(true);
      expect(findDatepicker().props('value')).toEqual(new Date(schedule.startsAt));
      expect(findTimeInput().element.value).toBe('08:45');
      expect(findCadenceInput().props('value')).toBe(SCAN_CADENCE_OPTIONS[3].value);
    });

    it('uses default cadence if stored value is empty', () => {
      createComponent({
        propsData: {
          value: {
            ...schedule,
            cadence: {},
          },
        },
      });

      expect(findCadenceInput().props('value')).toBe(SCAN_CADENCE_OPTIONS[0].value);
    });
  });
});
