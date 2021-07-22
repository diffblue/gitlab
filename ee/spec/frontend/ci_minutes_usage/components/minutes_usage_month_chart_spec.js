import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import { ciMinutesUsageMockData } from '../mock_data';

describe('Minutes usage by month chart component', () => {
  let wrapper;

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);

  const createComponent = () => {
    return shallowMount(MinutesUsageMonthChart, {
      propsData: {
        minutesUsageData: ciMinutesUsageMockData.data.ciMinutesUsage.nodes.map((cur) => [
          cur.month,
          cur.minutes,
        ]),
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an area chart component', () => {
    expect(findAreaChart().exists()).toBe(true);
  });
});
