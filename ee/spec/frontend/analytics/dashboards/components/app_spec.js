import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_DOCS_LINK,
} from 'ee/analytics/dashboards/constants';
import Component from 'ee/analytics/dashboards/components/app.vue';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';
import { mockChartConfig } from '../mock_data';

const mockProps = { chartConfigs: mockChartConfig };

jest.mock('~/analytics/shared/utils');

describe('Executive dashboard app', () => {
  let wrapper;

  function createComponent({ props = {} } = {}) {
    return shallowMountExtended(Component, {
      propsData: {
        ...mockProps,
        ...props,
      },
    });
  }

  const findComparisonCharts = () => wrapper.findAllComponents(ComparisonChart);
  const findDescription = () => wrapper.findByTestId('dashboard-description');

  describe('data requests', () => {
    beforeEach(async () => {
      wrapper = await createComponent();
    });

    it('renders the page title', () => {
      expect(wrapper.text()).toContain(DASHBOARD_TITLE);
    });

    it('renders the description', () => {
      expect(findDescription().text()).toContain(DASHBOARD_DESCRIPTION);
      expect(findDescription().findComponent(GlLink).attributes('href')).toBe(DASHBOARD_DOCS_LINK);
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
