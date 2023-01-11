import { shallowMount } from '@vue/test-utils';
import { GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
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
      stubs: { GlSprintf },
    });
  }

  const findComparisonCharts = () => wrapper.findAllComponents(ComparisonChart);
  const findAlert = () => wrapper.findComponent(GlAlert);

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

    it('renders the feedback issue link', () => {
      expect(findAlert().text()).toContain(
        'Beta feature: Leave your thoughts in the feedback issue',
      );
      expect(findAlert().findComponent(GlLink).attributes('href')).toBe(
        'https://gitlab.com/gitlab-org/gitlab/-/issues/381787',
      );
    });
  });
});
