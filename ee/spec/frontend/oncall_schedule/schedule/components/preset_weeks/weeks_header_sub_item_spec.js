import { shallowMount } from '@vue/test-utils';
import WeeksHeaderSubItemComponent from 'ee/oncall_schedules/components/schedule/components/preset_weeks/weeks_header_sub_item.vue';
import { getTimeframeForWeeksView } from 'ee/oncall_schedules/components/schedule/utils';
import { useFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('WeeksHeaderSubItemComponent', () => {
  let wrapper;
  // January 3rd, 2018 - current date (faked)
  useFakeDate(2018, 0, 3);
  const mockTimeframeInitialDate = new Date(2018, 0, 1);
  const mockTimeframeWeeks = getTimeframeForWeeksView(mockTimeframeInitialDate);

  function mountComponent({ timeframeItem = mockTimeframeWeeks[0] }) {
    wrapper = extendedWrapper(
      shallowMount(WeeksHeaderSubItemComponent, {
        propsData: {
          timeframeItem,
        },
        mocks: {
          $apollo: {
            mutate: jest.fn(),
          },
        },
      }),
    );
  }

  beforeEach(() => {
    mountComponent({});
  });

  const findSublabelValues = () => wrapper.findAll('[data-testid="sublabel-value"]');

  describe('computed', () => {
    describe('headerSubItems', () => {
      it('returns `headerSubItems` array of dates containing days of week from timeframeItem', () => {
        expect(wrapper.vm.headerSubItems).toBeInstanceOf(Array);
        expect(wrapper.vm.headerSubItems).toHaveLength(7);
        wrapper.vm.headerSubItems.forEach((subItem) => {
          expect(subItem).toBeInstanceOf(Date);
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `item-sublabel`', () => {
      expect(wrapper.classes()).toContain('item-sublabel');
    });

    it('renders sub item element with class `sublabel-value`', () => {
      expect(wrapper.find('.sublabel-value').exists()).toBe(true);
    });

    it('renders element with class `current-day-indicator-header` when hasToday is true', () => {
      // January 1st, 2018 is the first  day of the week-long timeframe
      // so as long as current date (faked January 3rd, 2018) is within week timeframe
      // current indicator will be rendered
      expect(wrapper.find('.current-day-indicator-header.preset-weeks').exists()).toBe(true);
    });

    it("sublabel has `gl-text-gray-900! gl-font-weight-bold` classes when it is for today's date", () => {
      // Timeframe starts at Jan 1, 2018, faked today is Jan 3, 2018 (3rd item in a week timeframe)
      expect(findSublabelValues().at(2).classes()).toEqual(
        expect.arrayContaining(['gl-text-gray-900!', 'gl-font-weight-bold']),
      );
    });
  });
});
