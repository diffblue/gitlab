import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MinutesUsageProjectChart from 'ee/usage_quotas/pipelines/components/minutes_usage_project_chart.vue';
import { getUsageDataByYearObject } from 'ee/usage_quotas/pipelines/utils';
import {
  Y_AXIS_PROJECT_LABEL,
  Y_AXIS_SHARED_RUNNER_LABEL,
} from 'ee/usage_quotas/pipelines/constants';
import { mockGetCiMinutesUsageNamespace } from '../mock_data';

const {
  data: { ciMinutesUsage },
} = mockGetCiMinutesUsageNamespace;
const usageDataByYearObject = getUsageDataByYearObject(ciMinutesUsage.nodes);

describe('Minutes usage by project chart component', () => {
  let wrapper;

  const findColumnChart = () => wrapper.findComponent(GlColumnChart);
  const findMonthDropdown = () => wrapper.findByTestId('minutes-usage-project-month-dropdown');
  const findAllMonthDropdownItems = () =>
    wrapper.findAllByTestId('minutes-usage-project-month-dropdown-item');

  const createComponent = (displaySharedRunner = false, selectedYear = '2022') => {
    wrapper = shallowMountExtended(MinutesUsageProjectChart, {
      propsData: {
        usageDataByYear: usageDataByYearObject,
        selectedYear,
        displaySharedRunnerData: displaySharedRunner,
      },
    });
  };

  describe('ci/cd minutes usage', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a column chart component with axis legends', () => {
      expect(findColumnChart().exists()).toBe(true);
      expect(findColumnChart().props('xAxisTitle')).toBe('Projects');
      expect(findColumnChart().props('yAxisTitle')).toBe(Y_AXIS_PROJECT_LABEL);
    });

    it('renders month dropdown component', () => {
      expect(findMonthDropdown().exists()).toBe(true);
      expect(findMonthDropdown().props('text')).toBe('August');
    });

    it('renders only the months with available minutes data', () => {
      expect(findAllMonthDropdownItems().length).toBe(1);
    });

    it('should contain a responsive attribute for the column chart', () => {
      expect(findColumnChart().attributes('responsive')).toBeDefined();
    });

    it('displays ci/cd minutes usage data on the chart', () => {
      const expectedChartData = [
        {
          data: [
            [
              ciMinutesUsage.nodes[ciMinutesUsage.nodes.length - 1].projects.nodes[0].project.name,
              ciMinutesUsage.nodes[ciMinutesUsage.nodes.length - 1].projects.nodes[0].minutes,
            ],
          ],
        },
      ];

      expect(findColumnChart().props('bars')).toEqual(expectedChartData);
    });
  });

  describe('when the selected year changes', () => {
    beforeEach(() => {
      createComponent(false, '2021');
    });

    it('changes the selected month in the month dropdown', async () => {
      expect(findMonthDropdown().props('text')).toBe('June');

      findAllMonthDropdownItems().at(1).vm.$emit('click');

      await nextTick();

      expect(findMonthDropdown().props('text')).toBe('July');
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
