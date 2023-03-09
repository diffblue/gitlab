import { shallowMount } from '@vue/test-utils';
import { REPORT_TYPES } from 'ee/vulnerabilities/components/generic_report/types/constants';
import NamedList from 'ee/vulnerabilities/components/generic_report/types/named_list.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

const TEST_DATA = {
  items: [
    { label: 'comment_1', name: 'url1', type: REPORT_TYPES.url, href: 'http://foo.bar' },
    { label: 'comment_2', name: 'url2', type: REPORT_TYPES.url, href: 'http://bar.baz' },
  ],
};

describe('ee/vulnerabilities/components/generic_report/types/named_list.vue', () => {
  let wrapper;

  const createWrapper = () =>
    extendedWrapper(
      shallowMount(NamedList, {
        propsData: {
          ...TEST_DATA,
        },
        // manual stubbing is needed because the component is dynamically imported
        stubs: {
          ReportItem: true,
        },
      }),
    );

  const findList = () => wrapper.findByRole('list');
  const findAllListItems = () => wrapper.findAllByTestId('listItem');
  const findItemValueWithLabel = (label) => wrapper.findByTestId(`listValue${label}`);

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

    it('renders a report-item', () => {
      expect(findItemValueWithLabel(item.label).exists()).toBe(true);
    });
  });
});
