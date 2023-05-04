import { shallowMount } from '@vue/test-utils';
import DaysHeaderSubItem from 'ee/oncall_schedules/components/schedule/components/preset_days/days_header_sub_item.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { HOURS_IN_DAY } from 'ee/oncall_schedules/constants';

describe('ee/oncall_schedules/components/schedule/components/preset_days/days_header_sub_item.vue', () => {
  let wrapper;
  const mockTimeframeItem = new Date(2021, 0, 13);

  function mountComponent({ timeframeItem }) {
    wrapper = extendedWrapper(
      shallowMount(DaysHeaderSubItem, {
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
    mountComponent({ timeframeItem: mockTimeframeItem });
  });

  const findDaysHeaderCurrentIndicator = () =>
    wrapper.findByTestId('day-item-sublabel-current-indicator');

  const findSublabels = () => wrapper.findAllByTestId('sublabel-value');

  describe('template', () => {
    it('renders component container element with class `item-sublabel`', () => {
      expect(wrapper.classes()).toContain('item-sublabel');
    });

    it('renders sub item elements for all items in HOURS_IN_DAY', () => {
      expect(findSublabels().length).toBe(HOURS_IN_DAY);
    });

    it('renders time indicator and bolded dark label when the hour matches current time', () => {
      const currentDate = new Date();
      mountComponent({ timeframeItem: currentDate });

      const currentHour = currentDate.getHours();
      expect(findSublabels().at(currentHour).classes()).toStrictEqual([
        'sublabel-value',
        'label-dark',
        'label-bold',
      ]);
      expect(findDaysHeaderCurrentIndicator().exists()).toBe(true);
    });
  });
});
