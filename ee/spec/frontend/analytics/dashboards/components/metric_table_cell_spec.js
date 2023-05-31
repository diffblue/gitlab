import { GlPopover, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MetricTableCell from 'ee/analytics/dashboards/components/metric_table_cell.vue';

describe('Metric table cell', () => {
  let wrapper;

  const identifier = 'deployment_frequency';
  const groupRequestPath = 'groups/test';
  const projectRequestPath = 'test/project';

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

  it('generates the drilldown link for groups', () => {
    createWrapper();
    expect(findMetricLabel().text()).toBe('Deployment Frequency');
    expect(findMetricLabel().attributes('href')).toBe(
      `/${groupRequestPath}/-/analytics/ci_cd?tab=deployment-frequency`,
    );
  });

  it('generates the drilldown link for projects', () => {
    createWrapper({ requestPath: projectRequestPath, isProject: true });
    expect(findMetricLabel().text()).toBe('Deployment Frequency');
    expect(findMetricLabel().attributes('href')).toBe(
      `/${projectRequestPath}/-/pipelines/charts?chart=deployment-frequency`,
    );
  });

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
});
