import { shallowMount } from '@vue/test-utils';
import WeeksHeaderItemComponent from 'ee/oncall_schedules/components/schedule/components/preset_weeks/weeks_header_item.vue';
import { getTimeframeForWeeksView } from 'ee/oncall_schedules/components/schedule/utils';
import { useFakeDate } from 'helpers/fake_date';

describe('WeeksHeaderItemComponent', () => {
  let wrapper;
  // January 3rd, 2018 - current date (faked)
  useFakeDate(2018, 0, 3);
  const mockTimeframeIndex = 0;
  const mockTimeframeInitialDate = new Date(2018, 0, 1);
  const mockTimeframeWeeks = getTimeframeForWeeksView(mockTimeframeInitialDate);

  function mountComponent({
    timeframeIndex = mockTimeframeIndex,
    timeframeItem = mockTimeframeWeeks[mockTimeframeIndex],
    timeframe = mockTimeframeWeeks,
  } = {}) {
    wrapper = shallowMount(WeeksHeaderItemComponent, {
      propsData: {
        timeframeIndex,
        timeframeItem,
        timeframe,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  const findHeaderLabel = () => wrapper.find('[data-testid="timeline-header-label"]');

  describe('lastDayOfCurrentWeek', () => {
    it('returns date object representing last day of the week as set in `timeframeItem`', () => {
      expect(wrapper.vm.lastDayOfCurrentWeek.getDate()).toBe(
        mockTimeframeWeeks[mockTimeframeIndex].getDate() + 7,
      );
    });
  });

  describe('timelineHeaderLabel', () => {
    it('returns string containing Month item in the timeframe', () => {
      expect(findHeaderLabel().text()).toBe('Jan');
    });
  });

  describe('timelineHeaderClass', () => {
    it('returns empty string when timeframeItem week is outside of current week', () => {
      mountComponent({
        timeframeIndex: 3,
        timeframeItem: new Date(2017, 0, 6),
      });
      expect(findHeaderLabel().classes()).not.toContain('label-bold');
    });

    it('returns string containing `label-bold` when current week is same as timeframeItem week', () => {
      expect(findHeaderLabel().classes()).toContain('label-bold');
    });
  });
});
