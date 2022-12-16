import { shallowMount } from '@vue/test-utils';
import Component from 'ee/analytics/dashboards/components/app.vue';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import { mockChartConfig } from '../mock_data';

const mockProps = { chartConfigs: mockChartConfig };

jest.mock('~/analytics/shared/utils');

describe('Executive dashboard app', () => {
  let wrapper;

  function createComponent({ props = {} } = {}) {
    return shallowMount(Component, {
      propsData: {
        ...mockProps,
        ...props,
      },
    });
  }

  const findComparisonCharts = () => wrapper.findAllComponents(ComparisonChart);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data requests', () => {
    beforeEach(async () => {
      wrapper = await createComponent();
    });

    it('renders the page title', () => {
      expect(wrapper.text()).toContain('DevOps metrics comparison (Beta)');
    });

    it('renders a chart component for each config', () => {
      const charts = findComparisonCharts();
      expect(charts.length).toBe(2);
    });

    it('correctly sets props for each chart', () => {
      const charts = findComparisonCharts();

      charts.wrappers.forEach((chart, index) => {
        const config = mockChartConfig[index];
        expect(chart.props()).toMatchObject({
          name: config.name,
          requestPath: config.fullPath,
          isProject: config.isProject,
        });
      });
    });
  });
});
