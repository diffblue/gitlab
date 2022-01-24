import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import CurrentDayIndicator from 'ee/roadmap/components/current_day_indicator.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate } from 'ee_jest/roadmap/mock_data';

const mockTimeframeQuarters = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.QUARTERS,
  initialDate: mockTimeframeInitialDate,
});
const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const mockTimeframeWeeks = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
  presetType: PRESET_TYPES.WEEKS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = () =>
  shallowMount(CurrentDayIndicator, {
    propsData: {
      presetType: PRESET_TYPES.MONTHS,
      timeframeItem: mockTimeframeMonths[0],
    },
  });

describe('CurrentDayIndicator', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('initializes currentDate and indicatorStyles props with default values', () => {
      const currentDate = new Date();

      expect(wrapper.vm.currentDate.getDate()).toBe(currentDate.getDate());
      expect(wrapper.vm.currentDate.getMonth()).toBe(currentDate.getMonth());
      expect(wrapper.vm.currentDate.getFullYear()).toBe(currentDate.getFullYear());
      expect(wrapper.vm.indicatorStyles).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('hasToday', () => {
      it('returns true when presetType is QUARTERS and currentDate is within current quarter', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentDate: mockTimeframeQuarters[0].range[1],
        });

        wrapper.setProps({
          presetType: PRESET_TYPES.QUARTERS,
          timeframeItem: mockTimeframeQuarters[0],
        });

        await nextTick();
        expect(wrapper.vm.hasToday).toBe(true);
      });

      it('returns true when presetType is MONTHS and currentDate is within current month', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentDate: new Date(2020, 0, 15),
        });

        wrapper.setProps({
          presetType: PRESET_TYPES.MONTHS,
          timeframeItem: new Date(2020, 0, 1),
        });

        await nextTick();
        expect(wrapper.vm.hasToday).toBe(true);
      });

      it('returns true when presetType is WEEKS and currentDate is within current week', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentDate: mockTimeframeWeeks[0],
        });

        wrapper.setProps({
          presetType: PRESET_TYPES.WEEKS,
          timeframeItem: mockTimeframeWeeks[0],
        });

        await nextTick();
        expect(wrapper.vm.hasToday).toBe(true);
      });
    });
  });

  describe('methods', () => {
    describe('getIndicatorStyles', () => {
      it('returns object containing `left` with value `34%` when presetType is QUARTERS', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentDate: mockTimeframeQuarters[0].range[1],
        });

        wrapper.setProps({
          presetType: PRESET_TYPES.QUARTERS,
          timeframeItem: mockTimeframeQuarters[0],
        });

        await nextTick();
        expect(wrapper.vm.getIndicatorStyles()).toEqual(
          expect.objectContaining({
            left: '34%',
          }),
        );
      });

      it('returns object containing `left` with value `48%` when presetType is MONTHS', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentDate: new Date(2020, 0, 15),
        });

        wrapper.setProps({
          presetType: PRESET_TYPES.MONTHS,
          timeframeItem: new Date(2020, 0, 1),
        });

        await nextTick();
        expect(wrapper.vm.getIndicatorStyles()).toEqual(
          expect.objectContaining({
            left: '48%',
          }),
        );
      });

      it('returns object containing `left` with value `7%` when presetType is WEEKS', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          currentDate: mockTimeframeWeeks[0],
        });

        wrapper.setProps({
          presetType: PRESET_TYPES.WEEKS,
          timeframeItem: mockTimeframeWeeks[0],
        });

        await nextTick();
        expect(wrapper.vm.getIndicatorStyles()).toEqual(
          expect.objectContaining({
            left: '7%',
          }),
        );
      });
    });
  });

  describe('template', () => {
    beforeEach(async () => {
      wrapper = createComponent();
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        currentDate: mockTimeframeMonths[0],
      });

      await nextTick();
    });

    it('renders span element containing class `current-day-indicator`', () => {
      expect(wrapper.classes('current-day-indicator')).toBe(true);
    });

    it('renders span element with style attribute containing `left: 3%;`', () => {
      expect(wrapper.attributes('style')).toBe('left: 3%;');
    });
  });
});
