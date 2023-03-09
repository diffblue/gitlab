import { shallowMount } from '@vue/test-utils';
import ScheduleShiftWrapper from 'ee/oncall_schedules/components/schedule/components/shifts/components/schedule_shift_wrapper.vue';
import ShiftItem from 'ee/oncall_schedules/components/schedule/components/shifts/components/shift_item.vue';
import { PRESET_TYPES, DAYS_IN_WEEK } from 'ee/oncall_schedules/constants';
import { nDaysAfter } from '~/lib/utils/datetime_utility';
import mockRotations from '../../../../mocks/mock_rotation.json';

const timeframeItem = new Date(2021, 0, 13);
const timeframe = [timeframeItem, nDaysAfter(timeframeItem, DAYS_IN_WEEK)];
const shift = mockRotations[0].shifts.nodes[0];

describe('ee/oncall_schedules/components/schedule/components/shifts/components/schedule_shift_wrapper.vue', () => {
  let wrapper;

  function createComponent({ props = { presetType: PRESET_TYPES.WEEKS }, data = {} } = {}) {
    wrapper = shallowMount(ScheduleShiftWrapper, {
      propsData: {
        timeframeItem,
        timeframe,
        rotation: mockRotations[0],
        ...props,
      },
      data() {
        return {
          timelineWidth: 0,
          ...data,
        };
      },
      mocks: {
        $apollo: {
          queries: {
            timelineWidth: 0,
          },
        },
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  const findShiftItems = () => wrapper.findAllComponents(ShiftItem);
  const updateShifts = (startsAt, endsAt) =>
    mockRotations[0].shifts.nodes.map((el) => ({ ...el, startsAt, endsAt }));

  describe('when the preset type is WEEKS', () => {
    it('should render a selection of week grid shifts inside the rotation', () => {
      expect(findShiftItems()).toHaveLength(2);
    });

    it.each`
      reason                                            | setTimeframeItem         | startsAt                      | endsAt
      ${'timeframe is an invalid date'}                 | ${new Date(NaN)}         | ${shift.startsAt}             | ${shift.endsAt}
      ${'shift start date is an invalid date'}          | ${timeframeItem}         | ${'Invalid date string'}      | ${shift.endsAt}
      ${'shift end date is an invalid date'}            | ${timeframeItem}         | ${shift.startsAt}             | ${'Invalid date string'}
      ${'shift is not inside the timeframe'}            | ${timeframeItem}         | ${'2021-03-12T10:00:00.000Z'} | ${'2021-03-16T10:00:00.000Z'}
      ${'timeframe does not represent the shift times'} | ${new Date(2021, 3, 21)} | ${shift.startsAt}             | ${shift.endsAt}
    `(`should not render a rotation item when $reason`, (data) => {
      const { setTimeframeItem, startsAt, endsAt } = data;
      const shifts = updateShifts(startsAt, endsAt);
      createComponent({
        props: {
          presetType: PRESET_TYPES.WEEKS,
          timeframeItem: setTimeframeItem,
          rotation: {
            ...mockRotations[0],
            shifts: {
              ...shifts,
            },
          },
        },
      });

      expect(findShiftItems().exists()).toBe(false);
    });
  });

  describe('when the preset type is DAYS', () => {
    it('should render a selection of day grid shifts inside the rotation', () => {
      createComponent({ props: { presetType: PRESET_TYPES.DAYS } });
      expect(findShiftItems()).toHaveLength(2);
    });

    it.each`
      reason                                            | setTimeframeItem         | startsAt                      | endsAt
      ${'timeframe is an invalid date'}                 | ${new Date(NaN)}         | ${shift.startsAt}             | ${shift.endsAt}
      ${'shift start date is an invalid date'}          | ${timeframeItem}         | ${'Invalid date string'}      | ${shift.endsAt}
      ${'shift end date is an invalid date'}            | ${timeframeItem}         | ${shift.startsAt}             | ${'Invalid date string'}
      ${'shift is not inside the timeframe'}            | ${timeframeItem}         | ${'2021-03-12T10:00:00.000Z'} | ${'2021-03-16T10:00:00.000Z'}
      ${'timeframe does not represent the shift times'} | ${new Date(2021, 3, 21)} | ${shift.startsAt}             | ${shift.endsAt}
    `(`should not render a rotation item when $reason`, (data) => {
      const { setTimeframeItem, startsAt, endsAt } = data;
      const shifts = updateShifts(startsAt, endsAt);
      createComponent({
        props: {
          presetType: PRESET_TYPES.DAYS,
          timeframeItem: setTimeframeItem,
          rotation: {
            ...mockRotations[0],
            shifts: {
              ...shifts,
            },
          },
        },
      });

      expect(findShiftItems().exists()).toBe(false);
    });
  });

  describe('when there are non-active participants in the rotation', () => {
    it('should render when there are no active participants', () => {
      createComponent({
        props: {
          presetType: PRESET_TYPES.DAYS,
          timeframeItem: timeframe,
          rotation: {
            ...mockRotations[0],
            participants: {
              nodes: [],
            },
          },
        },
      });
      expect(findShiftItems()).toHaveLength(2);
    });
  });
});
