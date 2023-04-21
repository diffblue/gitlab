import { mountExtended } from 'helpers/vue_test_utils_helper';
import { METRIC_TOOLTIPS } from '~/analytics/shared/constants';
import { CHART_GRADIENT, CHART_GRADIENT_INVERTED } from 'ee/analytics/dashboards/constants';
import ComparisonTable from 'ee/analytics/dashboards/components/comparison_table.vue';
import { mockComparativeTableData } from '../mock_data';

describe('Comparison table', () => {
  let wrapper;

  const groupRequestPath = 'groups/test';
  const projectRequestPath = 'test/project';
  const now = new Date();

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(ComparisonTable, {
      propsData: {
        tableData: mockComparativeTableData,
        requestPath: groupRequestPath,
        isProject: false,
        now,
        ...props,
      },
    });
  };

  const findMetricPopover = (identifier) => wrapper.findByTestId(`${identifier}_popover`);
  const findChart = () => wrapper.findByTestId('metric_chart');
  const findChartSkeleton = () => wrapper.findByTestId('metric_chart_skeleton');

  describe.each(Object.entries(METRIC_TOOLTIPS))(
    'popover for %s',
    (metric, { description, groupLink, projectLink, docsLink }) => {
      it('appends groupLink when isProject is false', () => {
        createWrapper();
        expect(findMetricPopover(metric).props('metric')).toMatchObject({
          description,
          links: [
            {
              url: `/${groupRequestPath}/${groupLink}`,
              label: wrapper.vm.$options.i18n.popoverDashboardLabel,
            },
            {
              url: docsLink,
              label: wrapper.vm.$options.i18n.popoverDocsLabel,
              docs_link: true,
            },
          ],
        });
      });

      it('appends projectLink when isProject is true', () => {
        createWrapper({ requestPath: projectRequestPath, isProject: true });
        expect(findMetricPopover(metric).props('metric')).toMatchObject({
          description,
          links: [
            {
              url: `/${projectRequestPath}/${projectLink}`,
              label: wrapper.vm.$options.i18n.popoverDashboardLabel,
            },
            {
              url: docsLink,
              label: wrapper.vm.$options.i18n.popoverDocsLabel,
              docs_link: true,
            },
          ],
        });
      });
    },
  );

  describe('sparkline chart', () => {
    const mockMetric = { identifier: 'lead_time', value: 'Lead Time' };

    beforeEach(() => {
      // Needed due to a deprecation in the GlSparkline API:
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2119
      // eslint-disable-next-line no-console
      console.warn = jest.fn();
    });

    it('renders the skeleton when there is no data', () => {
      createWrapper({ tableData: [{ metric: mockMetric }] });
      expect(findChart().exists()).toBe(false);
      expect(findChartSkeleton().exists()).toBe(true);
    });

    it('renders the line when there is data', () => {
      createWrapper({
        tableData: [
          {
            metric: mockMetric,
            chart: {
              data: [['', 1]],
            },
          },
        ],
      });
      expect(findChartSkeleton().exists()).toBe(false);
      expect(findChart().exists()).toBe(true);
    });

    it('applies the default gradient', () => {
      createWrapper({
        tableData: [
          {
            metric: mockMetric,
            chart: {
              data: [['', 1]],
            },
          },
        ],
      });
      expect(findChart().props('gradient')).toEqual(CHART_GRADIENT);
    });

    it('applies the inverted gradient when `invertTrendColor == true`', () => {
      createWrapper({
        tableData: [
          {
            metric: mockMetric,
            invertTrendColor: true,
            chart: {
              data: [['', 1]],
            },
          },
        ],
      });
      expect(findChart().props('gradient')).toEqual(CHART_GRADIENT_INVERTED);
    });
  });
});
