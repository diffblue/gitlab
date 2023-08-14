import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MinutesUsagePerProjectChart from 'ee/usage_quotas/pipelines/components/minutes_usage_per_project_chart.vue';
import { getUsageDataByYearByMonthAsObject } from 'ee/usage_quotas/pipelines/utils';
import {
  Y_AXIS_PROJECT_LABEL,
  Y_AXIS_SHARED_RUNNER_LABEL,
} from 'ee/usage_quotas/pipelines/constants';
import { mockGetCiMinutesUsageNamespaceProjects } from '../mock_data';

const {
  data: { ciMinutesUsage },
} = mockGetCiMinutesUsageNamespaceProjects;
const usageDataByYearObject = getUsageDataByYearByMonthAsObject(ciMinutesUsage.nodes);

describe('MinutesUsagePerProjectChart', () => {
  let wrapper;

  const findColumnChart = () => wrapper.findComponent(GlColumnChart);

  const createComponent = (displaySharedRunner = false, selectedYear = 2022, selectedMonth = 8) => {
    wrapper = shallowMountExtended(MinutesUsagePerProjectChart, {
      propsData: {
        usageDataByYear: usageDataByYearObject,
        selectedYear,
        selectedMonth,
        displaySharedRunnerData: displaySharedRunner,
      },
    });
  };

  describe('compute minutes usage', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a column chart component with axis legends', () => {
      expect(findColumnChart().exists()).toBe(true);
      expect(findColumnChart().props('xAxisTitle')).toBe('Projects');
      expect(findColumnChart().props('yAxisTitle')).toBe(Y_AXIS_PROJECT_LABEL);
    });

    it('should contain a responsive attribute for the column chart', () => {
      expect(findColumnChart().attributes('responsive')).toBeDefined();
    });

    it('displays compute usage data on the chart', () => {
      const expectedChartData = [
        {
          data: [
            [
              ciMinutesUsage.nodes[0].projects.nodes[0].project.name,
              ciMinutesUsage.nodes[0].projects.nodes[0].minutes,
            ],
          ],
        },
      ];

      expect(findColumnChart().props('bars')).toEqual(expectedChartData);
    });
  });

  describe('shared runners usage', () => {
    beforeEach(() => {
      createComponent(true);
    });

    it('displays shared runners y-axis title', () => {
      expect(findColumnChart().props('yAxisTitle')).toBe(Y_AXIS_SHARED_RUNNER_LABEL);
    });

    it('displays shared runners duration on the chart', () => {
      const expectedChartData = [
        {
          data: [
            [
              ciMinutesUsage.nodes[ciMinutesUsage.nodes.length - 1].projects.nodes[0].project.name,
              (
                ciMinutesUsage.nodes[ciMinutesUsage.nodes.length - 1].projects.nodes[0]
                  .sharedRunnersDuration / 60
              ).toFixed(2),
            ],
          ],
        },
      ];

      expect(findColumnChart().props('bars')).toEqual(expectedChartData);
    });
  });
});
