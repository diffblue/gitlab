import { GlTableLite } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DataTable from 'ee/analytics/analytics_dashboards/components/visualizations/data_table.vue';

describe('DataTable Visualization', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableHeaders = () => findTable().findAll('th');
  const findTableRowCells = (idx) => findTable().find('tbody').findAll('tr').at(idx).findAll('td');

  const data = [{ field_one: 'alpha', field_two: 'beta' }];

  const createWrapper = (mountFn = shallowMount, props = {}) => {
    wrapper = extendedWrapper(
      mountFn(DataTable, {
        propsData: {
          data,
          options: {},
          ...props,
        },
      }),
    );
  };

  describe('default behaviour', () => {
    it('should render the table with the expected attributes', () => {
      createWrapper();

      expect(findTable().attributes()).toMatchObject({
        responsive: '',
        hover: '',
      });
    });

    it('should render and style the table headers', () => {
      createWrapper(mount);

      const headers = findTableHeaders();

      expect(headers).toHaveLength(2);

      ['Field One', 'Field Two'].forEach((headerText, idx) => {
        expect(headers.at(idx).text()).toBe(headerText);
      });
    });

    it('should render and style the table cells', () => {
      createWrapper(mount);

      const rowCells = findTableRowCells(0);

      expect(rowCells).toHaveLength(2);

      Object.values(data[0]).forEach((value, idx) => {
        expect(rowCells.at(idx).text()).toBe(value);
        expect(rowCells.at(idx).classes()).toEqual(
          expect.arrayContaining(['gl-text-truncate', 'gl-max-w-0']),
        );
      });
    });
  });
});
