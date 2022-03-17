import { GlAlert } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import { ciMinutesUsageMockData } from '../mock_data';

const defaultProps = {
  minutesUsageData: ciMinutesUsageMockData.data.ciMinutesUsage.nodes.map((cur) => [
    cur.month,
    cur.minutes,
  ]),
};

describe('Minutes usage by month chart component', () => {
  let wrapper;

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(MinutesUsageMonthChart, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an area chart component', () => {
    createComponent();

    expect(findAreaChart().exists()).toBe(true);
    expect(findAlert().exists()).toBe(false);
  });

  it('should contain a responsive attribute for the area chart', () => {
    createComponent();

    expect(findAreaChart().attributes('responsive')).toBeDefined();
  });

  it('renders an alert when no data is available', () => {
    createComponent({ minutesUsageData: [] });

    expect(findAlert().exists()).toBe(true);
  });
});
