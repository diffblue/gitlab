import { mount } from '@vue/test-utils';

import { delay } from 'lodash';

import { nextTick } from 'vue';
import CurrentDayIndicator from 'ee/roadmap/components/current_day_indicator.vue';
import EpicItemComponent from 'ee/roadmap/components/epic_item.vue';
import EpicItemContainer from 'ee/roadmap/components/epic_item_container.vue';

import { DATE_RANGES, PRESET_TYPES } from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForRangeType } from 'ee/roadmap/utils/roadmap_utils';

import {
  mockTimeframeInitialDate,
  mockEpic,
  mockGroupId,
  mockFormattedChildEpic1,
} from 'ee_jest/roadmap/mock_data';

jest.mock('lodash/delay', () =>
  jest.fn((func) => {
    // eslint-disable-next-line no-param-reassign
    func.delay = jest.fn();
    return func;
  }),
);

let store;

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  epic = mockEpic,
  timeframe = mockTimeframeMonths,
  currentGroupId = mockGroupId,
  childLevel = 0,
  childrenEpics = {},
  childrenFlags = { [mockEpic.id]: { itemExpanded: false } },
  hasFiltersApplied = false,
}) => {
  return mount(EpicItemComponent, {
    store,
    stubs: {
      'epic-item-container': EpicItemContainer,
      'epic-item': EpicItemComponent,
    },
    propsData: {
      presetType,
      epic,
      timeframe,
      currentGroupId,
      childLevel,
      childrenEpics,
      childrenFlags,
      hasFiltersApplied,
    },
    data() {
      return {
        // Arbitrarily set the current date to be in timeframe[1] (2017-12-01)
        currentDate: timeframe[1],
      };
    },
  });
};

describe('EpicItemComponent', () => {
  let wrapper;

  beforeEach(() => {
    store = createStore();
    wrapper = createComponent({});
  });

  describe('startDate', () => {
    it('returns Epic.startDate when start date is within range', () => {
      expect(wrapper.vm.startDate).toBe(mockEpic.startDate);
    });

    it('returns Epic.originalStartDate when start date is out of range', () => {
      const mockStartDate = new Date(2018, 0, 1);
      const epic = { ...mockEpic, startDateOutOfRange: true, originalStartDate: mockStartDate };
      wrapper = createComponent({ epic });

      expect(wrapper.vm.startDate).toBe(mockStartDate);
    });
  });

  describe('endDate', () => {
    it('returns Epic.endDate when end date is within range', () => {
      expect(wrapper.vm.endDate).toBe(mockEpic.endDate);
    });

    it('returns Epic.originalEndDate when end date is out of range', () => {
      const mockEndDate = new Date(2018, 0, 1);
      const epic = { ...mockEpic, endDateOutOfRange: true, originalEndDate: mockEndDate };
      wrapper = createComponent({ epic });

      expect(wrapper.vm.endDate).toBe(mockEndDate);
    });
  });

  describe('timeframeString', () => {
    it('returns timeframe string correctly when both start and end dates are defined', () => {
      expect(wrapper.vm.timeframeString(mockEpic)).toBe('Nov 10, 2017 – Jun 2, 2018');
    });

    it('returns timeframe string correctly when no dates are defined', () => {
      const epic = { ...mockEpic, endDateUndefined: true, startDateUndefined: true };
      wrapper = createComponent({ epic });

      expect(wrapper.vm.timeframeString(epic)).toBe('No start and end date');
    });

    it('returns timeframe string correctly when only start date is defined', () => {
      const epic = { ...mockEpic, endDateUndefined: true };
      wrapper = createComponent({ epic });

      expect(wrapper.vm.timeframeString(epic)).toBe('Nov 10, 2017 – No end date');
    });

    it('returns timeframe string correctly when only end date is defined', () => {
      const epic = { ...mockEpic, startDateUndefined: true };
      wrapper = createComponent({ epic });

      expect(wrapper.vm.timeframeString(epic)).toBe('No start date – Jun 2, 2018');
    });

    it('returns timeframe string with hidden year for start date when both start and end dates are from same year', () => {
      const epic = { ...mockEpic, startDate: new Date(2018, 0, 1), endDate: new Date(2018, 3, 1) };
      wrapper = createComponent({ epic });

      expect(wrapper.vm.timeframeString(epic)).toBe('Jan 1 – Apr 1, 2018');
    });
  });

  describe('methods', () => {
    describe('removeHighlight', () => {
      it('should wait 3 seconds before toggling `epic.newEpic` from true to false', async () => {
        wrapper.setProps({
          epic: {
            ...wrapper.vm.epic,
            newEpic: true,
          },
        });

        wrapper.vm.removeHighlight();

        await nextTick();
        expect(delay).toHaveBeenCalledWith(expect.any(Function), 3000);
      });
    });
  });

  describe('template', () => {
    it('renders Epic item container', () => {
      expect(wrapper.find('.epics-list-item').exists()).toBe(true);
    });

    it('renders Epic item details element with class `epic-details-cell`', () => {
      expect(wrapper.find('.epic-details-cell').exists()).toBe(true);
    });

    it('renders Epic timeline element with class `epic-timeline-cell`', () => {
      expect(wrapper.find('.epic-timeline-cell').exists()).toBe(true);
    });

    it('does not render Epic item container element with class `epic-list-item-container` if epic is not expanded', () => {
      expect(wrapper.find('.epic-list-item-container').exists()).toBe(false);
    });

    it('renders Epic item container element with class `epic-list-item-container` if epic has children and is expanded', () => {
      wrapper = createComponent({
        childrenEpics: {
          1: [mockFormattedChildEpic1],
        },
        childrenFlags: {
          1: { itemExpanded: true },
          50: { itemExpanded: false },
        },
      });
      expect(wrapper.find('.epic-list-item-container').exists()).toBe(true);
    });

    it('renders current day indicator element', () => {
      expect(wrapper.findComponent(CurrentDayIndicator).exists()).toBe(true);
    });
  });
});
