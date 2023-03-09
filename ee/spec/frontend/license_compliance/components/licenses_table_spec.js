import { shallowMount } from '@vue/test-utils';
import LicensesTable from 'ee/license_compliance/components/licenses_table.vue';
import LicensesTableRow from 'ee/license_compliance/components/licenses_table_row.vue';
import { makeLicense } from './utils';

describe('LicensesTable component', () => {
  let wrapper;

  const factory = (propsData = {}) => {
    wrapper = shallowMount(LicensesTable, {
      propsData: { ...propsData },
    });
  };

  const findTableRowHeader = () => wrapper.find('.table-row-header');
  const findRows = () => wrapper.findAllComponents(LicensesTableRow);

  describe('given an empty list of licenses', () => {
    beforeEach(() => {
      factory({
        licenses: [],
        isLoading: false,
      });
    });

    it('renders the table headers', () => {
      expect(findTableRowHeader().element).toMatchSnapshot();
    });

    it('renders the empty license table', () => {
      expect(findRows()).toHaveLength(0);
    });
  });

  [true, false].forEach((isLoading) => {
    describe(`given a list of licenses (${isLoading ? 'loading' : 'loaded'})`, () => {
      let licenses;
      beforeEach(() => {
        licenses = [makeLicense(), makeLicense({ name: 'foo' })];

        factory({
          licenses,
          isLoading,
        });
      });

      it('renders the table headers', () => {
        expect(findTableRowHeader().element).toMatchSnapshot();
      });

      it('passes the correct props to the table rows', () => {
        expect(findRows()).toHaveLength(licenses.length);
        expect(findRows().wrappers.map((x) => x.props())).toEqual(
          licenses.map((license) => ({
            license,
            isLoading,
          })),
        );
      });
    });
  });
});
