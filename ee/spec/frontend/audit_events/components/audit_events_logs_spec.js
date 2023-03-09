import { shallowMount } from '@vue/test-utils';

import AuditEventsLog from 'ee/audit_events/components/audit_events_log.vue';
import AuditEventsExportButton from 'ee/audit_events/components/audit_events_export_button.vue';
import AuditEventsFilter from 'ee/audit_events/components/audit_events_filter.vue';
import AuditEventsTable from 'ee/audit_events/components/audit_events_table.vue';
import DateRangeField from 'ee/audit_events/components/date_range_field.vue';
import SortingField from 'ee/audit_events/components/sorting_field.vue';
import { AVAILABLE_TOKEN_TYPES } from 'ee/audit_events/constants';
import { createToken } from 'ee/audit_events/token_utils';
import createStore from 'ee/audit_events/store';

const TEST_SORT_BY = 'created_asc';
const TEST_START_DATE = new Date('2020-01-01');
const TEST_END_DATE = new Date('2020-02-02');
const TEST_FILTER_VALUE = [{ id: 50, type: 'User' }];

describe('AuditEventsLog', () => {
  let wrapper;
  let store;

  const findDateRangeField = () => wrapper.findComponent(DateRangeField);
  const findSortingField = () => wrapper.findComponent(SortingField);
  const findAuditFilter = () => wrapper.findComponent(AuditEventsFilter);
  const findAuditTable = () => wrapper.findComponent(AuditEventsTable);
  const findAuditExportButton = () => wrapper.findComponent(AuditEventsExportButton);

  const events = [{ foo: 'bar' }];
  const filterTokenOptions = AVAILABLE_TOKEN_TYPES.map((type) => ({ type }));
  const exportUrl = 'http://example.com/audit_log_reports.csv';

  const initComponent = ({ inject = {} } = {}) => {
    wrapper = shallowMount(AuditEventsLog, {
      store,
      provide: {
        isLastPage: true,
        filterTokenOptions,
        events,
        exportUrl,
        filterViewOnly: false,
        filterTokenValues: [],
        ...inject,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    Object.assign(store.state, {
      startDate: TEST_START_DATE,
      endDate: TEST_END_DATE,
      sortBy: TEST_SORT_BY,
      filterValue: TEST_FILTER_VALUE,
    });
  });

  describe('when initialized', () => {
    beforeEach(() => {
      initComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders audit events table', () => {
      expect(findAuditTable().props()).toEqual({
        events,
        isLastPage: true,
      });
    });

    it('renders audit events filter', () => {
      expect(findAuditFilter().props()).toEqual({
        filterTokenOptions,
        value: TEST_FILTER_VALUE,
        viewOnly: false,
      });
    });

    it('renders date range field', () => {
      expect(findDateRangeField().props()).toEqual({
        startDate: TEST_START_DATE,
        endDate: TEST_END_DATE,
      });
    });

    it('renders sorting field', () => {
      expect(findSortingField().props()).toEqual({ sortBy: TEST_SORT_BY });
    });

    it('renders the audit events export button', () => {
      expect(findAuditExportButton().props()).toEqual({
        exportHref:
          'http://example.com/audit_log_reports.csv?created_after=2020-01-01&created_before=2020-02-02',
      });
    });
  });

  describe('when a field is selected', () => {
    beforeEach(() => {
      jest.spyOn(store, 'dispatch').mockImplementation();
      initComponent();
    });

    it.each`
      name               | field                | action              | payload
      ${'date range'}    | ${DateRangeField}    | ${'setDateRange'}   | ${'test'}
      ${'sort by'}       | ${SortingField}      | ${'setSortBy'}      | ${'test'}
      ${'events filter'} | ${AuditEventsFilter} | ${'setFilterValue'} | ${'test'}
    `('for $name, it calls $handler', ({ field, action, payload }) => {
      expect(store.dispatch).not.toHaveBeenCalled();

      wrapper.findComponent(field).vm.$emit('selected', payload);

      expect(store.dispatch).toHaveBeenCalledWith(action, payload);
    });
  });

  describe('when the audit events export link is not present', () => {
    beforeEach(() => {
      initComponent({ inject: { exportUrl: '' } });
    });

    it('does not render the audit events export button', () => {
      expect(findAuditExportButton().exists()).toBe(false);
    });
  });

  describe('when `filterViewOnly` is true', () => {
    beforeEach(() => {
      return initComponent({ inject: { filterViewOnly: true } });
    });

    it('sets view-only to true on the audit events filter', () => {
      expect(findAuditFilter().props('viewOnly')).toBe(true);
    });
  });

  describe('when `filterTokenValues` has elements', () => {
    const filterTokenValues = [{ type: 'member', data: '@username' }];

    beforeEach(() => {
      jest.spyOn(store, 'dispatch').mockImplementation();

      return initComponent({ inject: { filterTokenValues } });
    });

    it('sets the filter value to the token values', () => {
      expect(store.dispatch).toHaveBeenCalledWith(
        'setFilterValue',
        filterTokenValues.map(createToken),
      );
    });
  });
});
