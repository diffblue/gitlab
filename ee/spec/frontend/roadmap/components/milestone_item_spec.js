import { GlLink } from '@gitlab/ui';
import MilestoneItemComponent from 'ee/roadmap/components/milestone_item.vue';
import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';
import { mockTimeframeInitialDate, mockMilestone2 } from 'ee_jest/roadmap/mock_data';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.THREE_YEARS,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

describe('MilestoneItemComponent', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(MilestoneItemComponent, {
      propsData: {
        presetType: PRESET_TYPES.MONTHS,
        milestone: mockMilestone2,
        timeframe: mockTimeframeMonths,
        timeframeItem: mockTimeframeMonths[16], // timeframe item where milestone begins,
        ...props,
      },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  describe('computed', () => {
    describe('startDateValues', () => {
      it('returns object containing date parts from milestone.startDate', () => {
        expect(wrapper.vm.startDateValues).toMatchObject({
          day: mockMilestone2.startDate.getDay(),
          date: mockMilestone2.startDate.getDate(),
          month: mockMilestone2.startDate.getMonth(),
          year: mockMilestone2.startDate.getFullYear(),
          time: mockMilestone2.startDate.getTime(),
        });
      });
    });

    describe('endDateValues', () => {
      it('returns object containing date parts from milestone.endDate', () => {
        expect(wrapper.vm.endDateValues).toMatchObject({
          day: mockMilestone2.endDate.getDay(),
          date: mockMilestone2.endDate.getDate(),
          month: mockMilestone2.endDate.getMonth(),
          year: mockMilestone2.endDate.getFullYear(),
          time: mockMilestone2.endDate.getTime(),
        });
      });
    });

    it('returns Milestone.startDate when start date is within range', () => {
      createComponent({ milestone: mockMilestone2 });

      expect(wrapper.vm.startDate).toBe(mockMilestone2.startDate);
    });

    it('returns Milestone.originalStartDate when start date is out of range', () => {
      const mockStartDate = new Date(2018, 0, 1);
      const mockMilestoneItem = {
        ...mockMilestone2,
        startDateOutOfRange: true,
        originalStartDate: mockStartDate,
      };
      createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.startDate).toBe(mockStartDate);
    });
  });

  describe('endDate', () => {
    it('returns Milestone.endDate when end date is within range', () => {
      createComponent({ milestone: mockMilestone2 });

      expect(wrapper.vm.endDate).toBe(mockMilestone2.endDate);
    });

    it('returns Milestone.originalEndDate when end date is out of range', () => {
      const mockEndDate = new Date(2018, 0, 1);
      const mockMilestoneItem = {
        ...mockMilestone2,
        endDateOutOfRange: true,
        originalEndDate: mockEndDate,
      };
      createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.endDate).toBe(mockEndDate);
    });
  });

  describe('timeframeString', () => {
    it('returns timeframe string correctly when both start and end dates are defined', () => {
      createComponent({ milestone: mockMilestone2 });

      expect(wrapper.vm.timeframeString(mockMilestone2)).toBe('Nov 10, 2017 – Jul 2, 2018');
    });

    it('returns timeframe string correctly when only start date is defined', () => {
      const mockMilestoneItem = { ...mockMilestone2, endDateUndefined: true };
      createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.timeframeString(mockMilestoneItem)).toBe('Nov 10, 2017 – No end date');
    });

    it('returns timeframe string correctly when only end date is defined', () => {
      const mockMilestoneItem = { ...mockMilestone2, startDateUndefined: true };
      createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.timeframeString(mockMilestoneItem)).toBe('No start date – Jul 2, 2018');
    });

    it('returns timeframe string with hidden year for start date when both start and end dates are from same year', () => {
      const mockMilestoneItem = {
        ...mockMilestone2,
        startDate: new Date(2018, 0, 1),
        endDate: new Date(2018, 3, 1),
      };
      createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.timeframeString(mockMilestoneItem)).toBe('Jan 1 – Apr 1, 2018');
    });
  });

  describe('template', () => {
    it('renders component container element class `timeline-bar-wrapper`', () => {
      expect(wrapper.classes()).toContain('timeline-bar-wrapper');
    });

    it('renders component element class `milestone-item-details`', () => {
      expect(wrapper.find('.milestone-item-details')).not.toBeNull();
    });

    it('renders Milestone item link element with class `milestone-url`', () => {
      expect(findLink()).not.toBeNull();
    });

    it('renders Milestone timeline bar element with class `timeline-bar`', () => {
      expect(wrapper.find('.timeline-bar')).not.toBeNull();
    });

    it('renders Milestone title element with class `milestone-item-title`', () => {
      expect(wrapper.findByText(mockMilestone2.title)).not.toBeNull();
    });
  });
});
