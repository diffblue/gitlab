import { shallowMount } from '@vue/test-utils';
import DaysHeaderItem from 'ee/oncall_schedules/components/schedule/components/preset_days/days_header_item.vue';
import { useFakeDate } from 'helpers/fake_date';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('ee/oncall_schedules/components/schedule/components/preset_days/days_header_item.vue', () => {
  let wrapper;
  // January 3rd, 2018 - current date (faked)
  useFakeDate(2018, 0, 3);
  const mockTimeframeInitialDate = new Date(2018, 0, 1);

  function mountComponent({ timeframeItem = mockTimeframeInitialDate } = {}) {
    wrapper = extendedWrapper(
      shallowMount(DaysHeaderItem, {
        propsData: {
          timeframeItem,
        },
      }),
    );
  }

  beforeEach(() => {
    mountComponent();
  });

  const findHeaderItem = () => wrapper.findByTestId('timeline-header-item');

  describe('timelineHeaderStyles', () => {
    it('returns string containing width calculated based on timeline cell width', () => {
      expect(findHeaderItem().attributes('style')).toContain('width: calc(');
    });
  });
});
