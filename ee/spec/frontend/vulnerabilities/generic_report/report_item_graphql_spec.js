import { shallowMount } from '@vue/test-utils';
import ReportItem, {
  GRAPHQL_TYPENAMES,
} from 'ee/vulnerabilities/components/generic_report/report_item_graphql.vue';
import { vulnerabilityDetails } from 'ee_jest/security_dashboard/components/pipeline/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('ee/vulnerabilities/components/generic_report/report_item_graphql.vue', () => {
  let wrapper;

  const createWrapper = ({ props } = {}) =>
    extendedWrapper(
      shallowMount(ReportItem, {
        propsData: {
          item: {},
          ...props,
        },
        // manual stubbing is needed because the components are dynamically imported
        stubs: GRAPHQL_TYPENAMES,
      }),
    );

  const findReportComponent = () => wrapper.findByTestId('reportComponent');

  describe.each(GRAPHQL_TYPENAMES)('with report type "%s"', (reportType) => {
    const testData = Object.values(vulnerabilityDetails).find((item) => item.type === reportType);
    const reportItem = { type: reportType, ...testData };

    beforeEach(() => {
      wrapper = createWrapper({ props: { item: reportItem } });
    });

    it('renders the corresponding component', () => {
      expect(findReportComponent().exists()).toBe(true);
    });

    it('passes the report data as props', () => {
      expect(findReportComponent().props()).toMatchObject({
        item: reportItem,
      });
    });
  });
});
