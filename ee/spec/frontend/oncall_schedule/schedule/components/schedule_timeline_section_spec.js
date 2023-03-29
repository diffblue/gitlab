import { shallowMount } from '@vue/test-utils';
import DaysHeaderItem from 'ee/oncall_schedules/components/schedule/components/preset_days/days_header_item.vue';
import WeeksHeaderItem from 'ee/oncall_schedules/components/schedule/components/preset_weeks/weeks_header_item.vue';
import ScheduleTimelineSection from 'ee/oncall_schedules/components/schedule/components/schedule_timeline_section.vue';
import { getTimeframeForWeeksView } from 'ee/oncall_schedules/components/schedule/utils';
import { PRESET_TYPES } from 'ee/oncall_schedules/constants';
import { getOncallSchedulesQueryResponse } from '../../mocks/apollo_mock';

describe('TimelineSectionComponent', () => {
  let wrapper;
  const mockTimeframeInitialDate = new Date(2018, 0, 1);
  const mockTimeframeWeeks = getTimeframeForWeeksView(mockTimeframeInitialDate);
  const schedule =
    getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];

  function createComponent({
    props = { presetType: PRESET_TYPES.WEEKS, timeframe: mockTimeframeWeeks },
  } = {}) {
    wrapper = shallowMount(ScheduleTimelineSection, {
      propsData: {
        schedule,
        ...props,
      },
      mocks: {
        $apollo: { mutate: () => {} },
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders component container element with class `timeline-section`', () => {
    expect(wrapper.html()).toContain('timeline-section');
  });

  it('renders empty header cell element with class `timeline-header-label`', () => {
    expect(wrapper.find('.timeline-header-label').exists()).toBe(true);
  });

  it('renders weeks header items based on timeframe data', () => {
    expect(wrapper.findAllComponents(WeeksHeaderItem)).toHaveLength(mockTimeframeWeeks.length);
  });

  it('renders days header items based on timeframe data', () => {
    createComponent({ props: { presetType: PRESET_TYPES.DAYS, timeframe: mockTimeframeWeeks } });
    expect(wrapper.findAllComponents(DaysHeaderItem)).toHaveLength(1);
  });
});
