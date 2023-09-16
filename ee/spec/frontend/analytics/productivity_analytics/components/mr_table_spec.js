import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MergeRequestTable from 'ee/analytics/productivity_analytics/components/mr_table.vue';
import MergeRequestTableRow from 'ee/analytics/productivity_analytics/components/mr_table_row.vue';
import { mockMergeRequests } from '../mock_data';

describe('MergeRequestTable component', () => {
  let wrapper;

  const defaultProps = {
    mergeRequests: mockMergeRequests,
    columnOptions: [
      { key: 'time_to_first_comment', label: 'Time from first commit until first comment' },
      { key: 'time_to_last_commit', label: 'Time from first comment to last commit' },
      { key: 'time_to_merge', label: 'Time from last commit to merge' },
    ],
    metricType: 'time_to_last_commit',
    metricLabel: 'Time from first comment to last commit',
    pageInfo: {},
  };

  const factory = (props = defaultProps) => {
    wrapper = shallowMount(MergeRequestTable, {
      propsData: { ...props },
    });
  };

  const findMergeRequestTableRows = () => wrapper.findAllComponents(MergeRequestTableRow);
  const findTableHeader = () => wrapper.find('.table-row-header');
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

  beforeEach(() => {
    factory();
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('template', () => {
    it('renders the table header and the column titles', () => {
      expect(findTableHeader().exists()).toBe(true);
      expect(findTableHeader().text()).toContain('Title');
      expect(findTableHeader().text()).toContain('Time to merge');
    });

    it('renders a dropdown with the column options', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('renders a dropdown item for each item in columnOptions', () => {
      expect(findDropdown().props('items')).toHaveLength(
        Object.keys(defaultProps.columnOptions).length,
      );
    });

    it('renders a row for every MR', () => {
      expect(findMergeRequestTableRows()).toHaveLength(2);
    });
  });

  describe('computed', () => {
    describe('metricDropdownLabel', () => {
      it('returns "Time from first comment to last commit"', () => {
        expect(wrapper.vm.metricDropdownLabel).toBe('Time from first comment to last commit');
      });
    });
  });

  describe('columnMetricChange', () => {
    it('emits the metric key when item is selected from the dropdown', async () => {
      findDropdown().vm.$emit('select', defaultProps.columnOptions[0].key);

      await nextTick();
      expect(wrapper.emitted().columnMetricChange[0]).toEqual(['time_to_first_comment']);
    });
  });
});
