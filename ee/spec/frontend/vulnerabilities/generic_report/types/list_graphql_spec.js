import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import List from 'ee/vulnerabilities/components/generic_report/types/list_graphql.vue';

const TEST_DATA = {
  items: [
    { type: 'VulnerabilityDetailsUrl', href: 'https://foo.bar' },
    { type: 'VulnerabilityDetailsUrl', href: 'https://bar.baz' },
  ],
  listItem: { type: 'VulnerabilityDetailList', items: [] },
};

describe('ee/vulnerabilities/components/generic_report/types/list_graphql.vue', () => {
  let wrapper;

  const createWrapper = (options = {}) =>
    shallowMountExtended(List, {
      propsData: {
        items: TEST_DATA.items,
      },
      // manual stubbing is needed because the component is dynamically imported
      stubs: {
        ReportItem: true,
      },
      ...options,
    });

  const findList = () => wrapper.findByTestId('generic-report-type-list');
  const findListItems = () => wrapper.findAllByTestId('generic-report-type-list-item');
  const findReportItems = () => wrapper.findAllByTestId('report-item');

  it('renders a list', () => {
    wrapper = createWrapper();
    expect(findList().exists()).toBe(true);
  });

  it('renders a report-item for each item', () => {
    wrapper = createWrapper();
    expect(findReportItems()).toHaveLength(TEST_DATA.items.length);
  });

  describe.each([true, false])('when containing a nested list is "%s"', (hasNestedList) => {
    const items = [...TEST_DATA.items];

    if (hasNestedList) {
      items.push(TEST_DATA.listItem);
    }

    beforeEach(() => {
      wrapper = createWrapper({
        propsData: {
          items,
        },
      });
    });

    it('applies the correct classes to the list', () => {
      expect(findList().classes().includes('generic-report-list-nested')).toBe(hasNestedList);
    });

    it('applies the correct classes to the list items', () => {
      const lastItem = findListItems().at(-1);
      expect(lastItem.classes().includes('gl-list-style-none!')).toBe(hasNestedList);
    });
  });
});
