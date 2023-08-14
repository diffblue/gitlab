import timezoneMock from 'timezone-mock';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MinutesUsagePerMonth from 'ee/usage_quotas/pipelines/components/minutes_usage_per_month_chart.vue';
import { getUsageDataByYearAsArray } from 'ee/usage_quotas/pipelines/utils';
import { mockGetCiMinutesUsageNamespace } from '../mock_data';

const {
  data: { ciMinutesUsage },
} = mockGetCiMinutesUsageNamespace;
const usageDataByYear = getUsageDataByYearAsArray(ciMinutesUsage.nodes);

describe('MinutesUsagePerMonth', () => {
  let wrapper;

  const findAreaChart = () => wrapper.findComponent(GlAreaChart);

  const createComponent = () => {
    wrapper = shallowMountExtended(MinutesUsagePerMonth, {
      propsData: {
        usageDataByYear,
        selectedYear: 2022,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders an area chart component', () => {
    expect(findAreaChart().exists()).toBe(true);
  });

  it('should contain a responsive attribute for the area chart', () => {
    expect(findAreaChart().attributes('responsive')).toBeDefined();
  });

  describe.each`
    timezone
    ${'Europe/London'}
    ${'US/Pacific'}
  `('when viewing in timezone', ({ timezone }) => {
    describe(timezone, () => {
      beforeEach(() => {
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
