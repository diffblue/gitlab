import timezoneMock from 'timezone-mock';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MinutesUsageMonthChart from 'ee/usage_quotas/pipelines/components/minutes_usage_month_chart.vue';
import { mockGetCiMinutesUsageNamespace } from '../mock_data';

const {
  data: { ciMinutesUsage },
} = mockGetCiMinutesUsageNamespace;

describe('Minutes usage by month chart component', () => {
  let wrapper;

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);
  const findYearDropdown = () => wrapper.findByTestId('minutes-usage-month-dropdown');
  const findAllYearDropdownItems = () =>
    wrapper.findAllByTestId('minutes-usage-month-dropdown-item');

  const createComponent = (usageData = ciMinutesUsage.nodes) => {
    wrapper = shallowMountExtended(MinutesUsageMonthChart, {
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

  it('renders an area chart component', () => {
    expect(findAreaChart().exists()).toBe(true);
  });

  it('should contain a responsive attribute for the area chart', () => {
    expect(findAreaChart().attributes('responsive')).toBeDefined();
  });

  it('renders year dropdown component', () => {
    expect(findYearDropdown().exists()).toBe(true);
    expect(findYearDropdown().props('text')).toBe('2022');
  });

  it('renders only the years with available minutes data', () => {
    expect(findAllYearDropdownItems().length).toBe(2);
  });

  it('should change the selected year in the year dropdown', async () => {
    expect(findYearDropdown().props('text')).toBe('2022');

    findAllYearDropdownItems().at(1).vm.$emit('click');

    await nextTick();

    expect(findYearDropdown().props('text')).toBe('2021');
  });

  describe.each`
    timezone
    ${'Europe/London'}
    ${'US/Pacific'}
  `('when viewing in timezone', ({ timezone }) => {
    describe(timezone, () => {
      beforeEach(async () => {
        createComponent();
        timezoneMock.register(timezone);
      });

      afterEach(() => {
        timezoneMock.unregister();
      });

      it('has the right start month', () => {
        expect(findAreaChart().props('data')[0].data[0][0]).toEqual('Aug 2022');
      });
    });
  });
});
