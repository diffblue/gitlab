import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SharedRunnerUsageMonthChart from 'ee/usage_quotas/pipelines/components/shared_runner_usage_month_chart.vue';
import { mockGetCiMinutesUsageNamespace } from '../mock_data';

const {
  data: { ciMinutesUsage },
} = mockGetCiMinutesUsageNamespace;

describe('Shared runner usage month chart component', () => {
  let wrapper;

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);
  const findYearDropdown = () => wrapper.findByTestId('shared-runner-usage-month-dropdown');
  const findAllYearDropdownItems = () =>
    wrapper.findAllByTestId('shared-runner-usage-month-dropdown-item');

  const createComponent = (usageData = ciMinutesUsage.nodes) => {
    wrapper = shallowMountExtended(SharedRunnerUsageMonthChart, {
      propsData: {
        ciMinutesUsage: usageData,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a area chart component with axis legends', () => {
    expect(findAreaChart().exists()).toBe(true);
    expect(findAreaChart().props('option').xAxis.name).toBe('Month');
    expect(findAreaChart().props('option').yAxis.name).toBe('Duration (min)');
  });

  it('renders year dropdown component', () => {
    expect(findYearDropdown().exists()).toBe(true);
    expect(findYearDropdown().props('text')).toBe('2022');
  });

  it('renders only the years with available minutes data', () => {
    expect(findAllYearDropdownItems().length).toBe(2);
  });

  it('should contain a responsive attribute for the column chart', () => {
    expect(findAreaChart().attributes('responsive')).toBeDefined();
  });

  it('should change the selected year in the year dropdown', async () => {
    expect(findYearDropdown().props('text')).toBe('2022');

    findAllYearDropdownItems().at(1).vm.$emit('click');

    await nextTick();

    expect(findYearDropdown().props('text')).toBe('2021');
  });
});
