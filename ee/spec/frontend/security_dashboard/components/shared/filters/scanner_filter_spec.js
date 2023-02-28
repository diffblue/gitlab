import { GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FilterItem from 'ee/security_dashboard/components/shared/filters/filter_item.vue';
import ScannerFilter from 'ee/security_dashboard/components/shared/filters/scanner_filter.vue';
import { DEFAULT_SCANNER, SCANNER_ID_PREFIX } from 'ee/security_dashboard/constants';
import { vendorScannerFilter } from 'ee/security_dashboard/helpers';

Vue.use(VueRouter);
const router = new VueRouter();

const createScannerConfig = (vendor, reportType, id) => ({
  vendor,
  report_type: reportType,
  id,
});

const defaultScanners = [
  createScannerConfig(DEFAULT_SCANNER, 'DEPENDENCY_SCANNING', 1),
  createScannerConfig(DEFAULT_SCANNER, 'DEPENDENCY_SCANNING', 2),
  createScannerConfig(DEFAULT_SCANNER, 'SAST', 3),
  createScannerConfig(DEFAULT_SCANNER, 'SAST', 4),
  createScannerConfig(DEFAULT_SCANNER, 'SECRET_DETECTION', 5),
  createScannerConfig(DEFAULT_SCANNER, 'CONTAINER_SCANNING', 6),
  createScannerConfig(DEFAULT_SCANNER, 'DAST', 7),
  createScannerConfig(DEFAULT_SCANNER, 'DAST', 8),
  createScannerConfig(DEFAULT_SCANNER, 'CLUSTER_IMAGE_SCANNING', 9),
];

const customScanners = [
  ...defaultScanners,
  createScannerConfig('Custom', 'SAST', 10),
  createScannerConfig('Custom', 'SAST', 11),
  createScannerConfig('Custom', 'DAST', 12),
];

describe('Scanner Filter component', () => {
  let wrapper;
  let filter;

  const createWrapper = ({ scanners = customScanners } = {}) => {
    filter = cloneDeep(vendorScannerFilter);

    wrapper = shallowMountExtended(ScannerFilter, {
      router,
      propsData: { filter },
      provide: { scanners },
    });
  };

  const getTestIds = (selector) =>
    wrapper.findAllComponents(selector).wrappers.map((x) => x.attributes('data-testid'));

  const findDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findDropdownDivider = () => wrapper.findComponent(GlDropdownDivider);
  const findAllFilterItems = () => wrapper.findAllComponents(FilterItem);
  const findHeader = () => wrapper.findByTestId('GitLabHeader');

  afterEach(() => {
    // Clear out the querystring if one exists, it persists between tests.
    if (router.currentRoute.query[filter.id]) {
      router.replace('/');
    }
  });

  describe('default scanners only', () => {
    it('shows the dropdown items with no headers or dividers', () => {
      createWrapper({ scanners: defaultScanners });
      const options = getTestIds(FilterItem);
      const expectedOptions = ['all', ...filter.options.map((x) => x.id)];

      expect(options).toEqual(expectedOptions);
      expect(findDropdownDivider().exists()).toBe(false);
      expect(findDropdownItem().exists()).toBe(false);
    });
  });

  describe('default and custom scanners', () => {
    it('shows the correct dropdown items', () => {
      createWrapper();

      const options = getTestIds(FilterItem);
      const expectedOptions = [
        'all',
        ...filter.options.map((x) => x.id),
        'Custom.SAST',
        'Custom.DAST',
      ];

      const headers = getTestIds(GlDropdownItem);
      const expectedHeaders = ['GitLabHeader', 'CustomHeader'];

      expect(options).toEqual(expectedOptions);
      expect(headers).toEqual(expectedHeaders);
    });

    it('toggles selection of all items in a group when the group header is clicked', async () => {
      createWrapper();

      /**
       * First filter item for all item
       */
      const NUMBER_OF_FILTER_ITEMS = findAllFilterItems().length - 1;
      const selectFilterItemsWhereIsChecked = (isChecked) =>
        findAllFilterItems().wrappers.filter((x) => x.props('isChecked') === isChecked);

      await findHeader().trigger('click');
      expect(selectFilterItemsWhereIsChecked(true)).toHaveLength(filter.options.length);

      await findHeader().trigger('click');
      expect(selectFilterItemsWhereIsChecked(false)).toHaveLength(NUMBER_OF_FILTER_ITEMS);
    });

    it('emits filter-changed event with expected data for selected options', async () => {
      const ids = ['GitLab.SAST', 'Custom.SAST', 'GitLab.API_FUZZING', 'GitLab.COVERAGE_FUZZING'];
      router.replace({ query: { [vendorScannerFilter.id]: ids } });
      const selectedScanners = customScanners.filter((x) =>
        ids.includes(`${x.vendor}.${x.report_type}`),
      );
      createWrapper();
      await nextTick();

      expect(wrapper.emitted('filter-changed')[0][0]).toEqual({
        scannerId: expect.arrayContaining([
          ...selectedScanners.map((x) => `${SCANNER_ID_PREFIX}${x.id}`),
          `${SCANNER_ID_PREFIX}COVERAGE_FUZZING:null`,
          `${SCANNER_ID_PREFIX}API_FUZZING:null`,
        ]),
      });
    });
  });
});
