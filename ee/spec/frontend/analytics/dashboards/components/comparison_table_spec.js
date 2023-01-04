import { mountExtended } from 'helpers/vue_test_utils_helper';
import { METRIC_TOOLTIPS } from 'ee/analytics/dashboards/constants';
import ComparisonTable from 'ee/analytics/dashboards/components/comparison_table.vue';
import { mockComparativeTableData } from '../mock_data';

describe('Comparison chart', () => {
  let wrapper;

  const groupRequestPath = 'groups/test';
  const projectRequestPath = 'test/project';

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(ComparisonTable, {
      propsData: {
        tableData: mockComparativeTableData,
        requestPath: groupRequestPath,
        isProject: false,
        ...props,
      },
    });
  };

  const findMetricPopover = (identifier) => wrapper.findByTestId(`${identifier}_popover`);

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
});
