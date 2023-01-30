import { GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ReportItem from 'ee/vulnerabilities/components/generic_report/report_item_graphql.vue';
import Table from 'ee/vulnerabilities/components/generic_report/types/table_graphql.vue';

const TEST_DATA = {
  headers: [{ type: 'VulnerabilityDetailText', value: 'foo ' }],
  rows: [{ row: [{ type: 'VulnerabilityDetailUrl', href: 'bar' }] }],
};

describe('ee/vulnerabilities/components/generic_report/types/table_graphql.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return mountExtended(Table, {
      propsData: {
        ...TEST_DATA,
      },
      stubs: {
        'report-item': ReportItem,
      },
    });
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders a table', () => {
    expect(wrapper.findComponent(GlTableLite).exists()).toBe(true);
  });

  it('renders a table header containing the given report type', () => {
    expect(wrapper.find('thead').findComponent(ReportItem).props('item')).toMatchObject(
      TEST_DATA.headers.at(0),
    );
  });

  it('renders a table cell containing the given report type', () => {
    expect(wrapper.find('tbody').findComponent(ReportItem).props('item')).toMatchObject(
      TEST_DATA.rows.at(0).row.at(0),
    );
  });
});
