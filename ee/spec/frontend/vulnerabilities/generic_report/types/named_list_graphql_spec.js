import { shallowMount } from '@vue/test-utils';
import NamedList from 'ee/vulnerabilities/components/generic_report/types/named_list_graphql.vue';
import ReportItem from 'ee/vulnerabilities/components/generic_report/report_item_graphql.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_DATA = {
  items: [
    {
      name: 'url1',
      fieldName: 'comment_1',
      value: { type: 'VulnerabilityDetailUrl', href: 'http://foo.bar' },
    },
    {
      name: 'url2',
      fieldName: 'comment_2',
      value: { type: 'VulnerabilityDetailUrl', href: 'http://bar.baz' },
    },
  ],
};

describe('ee/vulnerabilities/components/generic_report/types/named_list_graphql.vue', () => {
  let wrapper;

  const createWrapper = () =>
    extendedWrapper(
      shallowMount(NamedList, {
        propsData: {
          ...TEST_DATA,
        },
        // manual stubbing is needed because the component is dynamically imported
        stubs: {
          ReportItem,
        },
      }),
    );

  const findList = () => wrapper.findByRole('list');
  const findAllListItems = () => wrapper.findAllByTestId('listItem');
  const findItemValueWithFieldName = (fieldName) => wrapper.findByTestId(`listValue${fieldName}`);

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('renders a list element', () => {
    expect(findList().exists()).toBe(true);
  });

  it('renders all list items', () => {
    expect(findAllListItems()).toHaveLength(Object.values(TEST_DATA.items).length);
  });

  describe.each(TEST_DATA.items)('list item: %s', (item) => {
    it(`renders the item's name`, () => {
      expect(wrapper.findByText(item.name).exists()).toBe(true);
    });

    it('renders a report-item with the correct data', () => {
      expect(findItemValueWithFieldName(item.fieldName).props()).toMatchObject({
        item: item.value,
      });
    });
  });
});
