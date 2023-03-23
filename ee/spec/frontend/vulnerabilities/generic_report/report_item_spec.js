import { shallowMount } from '@vue/test-utils';
import ReportItem from 'ee/vulnerabilities/components/generic_report/report_item.vue';
import { REPORT_COMPONENTS } from 'ee/vulnerabilities/components/generic_report/types/component_map';
import { REPORT_TYPES } from 'ee/vulnerabilities/components/generic_report/types/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_DATA = {
  [REPORT_TYPES.url]: {
    href: 'http://foo.com',
  },
  [REPORT_TYPES.list]: {
    items: [],
  },
  [REPORT_TYPES.diff]: {
    before: 'foo',
    after: 'bar',
  },
  [REPORT_TYPES.text]: {
    name: 'some-string-field',
    value: 'some-value',
  },
  [REPORT_TYPES.value]: {
    name: 'some-numeric-field',
    value: 15,
  },
  [REPORT_TYPES.moduleName]: {
    moduleName: 'foo.c',
    offset: 15,
  },
  [REPORT_TYPES.fileLocation]: {
    fileName: 'index.js',
    lineStart: '1',
    lineEnd: '2',
  },
  [REPORT_TYPES.markdown]: {
    name: 'Markdown:',
    value: 'Checkout [GitLab](http://gitlab.com)',
  },
};

describe('ee/vulnerabilities/components/generic_report/report_item.vue', () => {
  let wrapper;

  const createWrapper = ({ props } = {}) =>
    extendedWrapper(
      shallowMount(ReportItem, {
        propsData: {
          item: {},
          ...props,
        },
        // manual stubbing is needed because the components are dynamically imported
        stubs: Object.keys(REPORT_COMPONENTS),
      }),
    );

  const findReportComponent = () => wrapper.findByTestId('reportComponent');

  describe.each(Object.values(REPORT_TYPES))('with report type "%s"', (reportType) => {
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
