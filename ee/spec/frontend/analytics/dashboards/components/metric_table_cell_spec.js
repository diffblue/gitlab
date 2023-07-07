import { GlPopover, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MetricTableCell from 'ee/analytics/dashboards/components/metric_table_cell.vue';
import { CLICK_METRIC_DRILLDOWN_LINK_ACTION } from 'ee/analytics/dashboards/constants';

describe('Metric table cell', () => {
  let wrapper;

  const identifier = 'deployment_frequency';
  const groupRequestPath = 'groups/test';
  const groupMetricPath = '-/analytics/ci_cd?tab=deployment-frequency';
  const projectRequestPath = 'test/project';
  const projectMetricPath = '-/pipelines/charts?chart=deployment-frequency';

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(MetricTableCell, {
      propsData: {
        identifier,
        requestPath: groupRequestPath,
        isProject: false,
        ...props,
      },
    });
  };

  const findMetricLabel = () => wrapper.findByTestId('metric_label');
  const findInfoIcon = () => wrapper.findByTestId('info_icon');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlPopover).findComponent(GlLink);

  it.each`
    isProject | relativeUrlRoot | requestPath           | metricPath
    ${false}  | ${'/'}          | ${groupRequestPath}   | ${groupMetricPath}
    ${true}   | ${'/'}          | ${projectRequestPath} | ${projectMetricPath}
    ${false}  | ${'/path'}      | ${groupRequestPath}   | ${groupMetricPath}
    ${true}   | ${'/path'}      | ${projectRequestPath} | ${projectMetricPath}
  `(
    'generates the correct drilldown link',
    ({ isProject, relativeUrlRoot, requestPath, metricPath }) => {
      const rootPath = relativeUrlRoot === '/' ? '' : relativeUrlRoot;

      gon.relative_url_root = relativeUrlRoot;
      createWrapper({ requestPath, isProject });

      expect(findMetricLabel().text()).toBe('Deployment Frequency');
      expect(findMetricLabel().attributes('href')).toBe(`${rootPath}/${requestPath}/${metricPath}`);
    },
  );

  it('shows the popover when the info icon is clicked', () => {
    createWrapper();
    expect(findPopover().props('target')).toBe(findInfoIcon().attributes('id'));
  });

  it('renders popover content based on the metric identifier', () => {
    createWrapper();
    expect(findPopover().props('title')).toBe('Deployment Frequency');
    expect(findPopover().text()).toContain('Average number of deployments to production per day');
    expect(findPopoverLink().attributes('href')).toBe(
      '/help/user/analytics/dora_metrics#deployment-frequency',
    );
    expect(findPopoverLink().text()).toBe(MetricTableCell.i18n.docsLabel);
  });

  it('adds tracking data attributes to drilldown link', () => {
    createWrapper();

    expect(findMetricLabel().attributes('data-track-action')).toBe(
      CLICK_METRIC_DRILLDOWN_LINK_ACTION,
    );
    expect(findMetricLabel().attributes('data-track-label')).toBe(`${identifier}_drilldown`);
  });
});
