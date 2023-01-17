import { shallowMount } from '@vue/test-utils';
import ReportItem from 'ee/vulnerabilities/components/generic_report/report_item_graphql.vue';
import {
  GRAPHQL_TYPENAME_DIFF,
  GRAPHQL_TYPENAME_CODE,
  GRAPHQL_TYPENAME_URL,
  GRAPHQL_TYPENAMES,
} from 'ee/vulnerabilities/components/generic_report/types/constants';
import {
  vulnerabilityDetailDiff,
  vulnerabilityDetailCode,
  vulnerabilityDetailUrl,
} from 'ee_jest/security_dashboard/components/pipeline/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_DATA = {
  [GRAPHQL_TYPENAME_URL]: vulnerabilityDetailUrl,
  [GRAPHQL_TYPENAME_DIFF]: vulnerabilityDetailDiff,
  [GRAPHQL_TYPENAME_CODE]: vulnerabilityDetailCode,
};

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

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each(GRAPHQL_TYPENAMES)('with report type "%s"', (reportType) => {
    const reportItem = { type: reportType, ...TEST_DATA[reportType] };

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
