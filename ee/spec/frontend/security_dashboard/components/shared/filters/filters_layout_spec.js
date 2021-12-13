import { shallowMount } from '@vue/test-utils';
import ActivityFilter from 'ee/security_dashboard/components/shared/filters/activity_filter.vue';
import Filters from 'ee/security_dashboard/components/shared/filters/filters_layout.vue';
import ProjectFilter from 'ee/security_dashboard/components/shared/filters/project_filter.vue';
import ScannerFilter from 'ee/security_dashboard/components/shared/filters/scanner_filter.vue';
import SimpleFilter from 'ee/security_dashboard/components/shared/filters/simple_filter.vue';
import { simpleScannerFilter } from 'ee/security_dashboard/helpers';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('First class vulnerability filters component', () => {
  let wrapper;

  const findSimpleFilters = () => wrapper.findAllComponents(SimpleFilter);
  const findSimpleScannerFilter = () => wrapper.findByTestId(simpleScannerFilter.id);
  const findVendorScannerFilter = () => wrapper.findComponent(ScannerFilter);
  const findActivityFilter = () => wrapper.findComponent(ActivityFilter);
  const findProjectFilter = () => wrapper.findComponent(ProjectFilter);

  const createComponent = ({ provide } = {}) => {
    return extendedWrapper(
      shallowMount(Filters, {
        provide: {
          dashboardType: DASHBOARD_TYPES.PROJECT,
          ...provide,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on render without project filter', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('should render the default filters', () => {
      expect(findSimpleFilters()).toHaveLength(2);
      expect(findActivityFilter().exists()).toBe(true);
      expect(findProjectFilter().exists()).toBe(false);
    });

    it('should emit filterChange when a filter is changed', () => {
      const options = { foo: 'bar' };
      findActivityFilter().vm.$emit('filter-changed', options);

      expect(wrapper.emitted('filterChange')[0][0]).toEqual(options);
    });
  });

  describe('project filter', () => {
    it.each`
      dashboardType               | isShown
      ${DASHBOARD_TYPES.PROJECT}  | ${false}
      ${DASHBOARD_TYPES.PIPELINE} | ${false}
      ${DASHBOARD_TYPES.GROUP}    | ${true}
      ${DASHBOARD_TYPES.INSTANCE} | ${true}
    `(
      'on the $dashboardType report the project filter shown is $isShown',
      ({ dashboardType, isShown }) => {
        wrapper = createComponent({ provide: { dashboardType } });

        expect(findProjectFilter().exists()).toBe(isShown);
      },
    );
  });

  describe('activity filter', () => {
    beforeEach(() => {
      wrapper = createComponent({ provide: { dashboardType: DASHBOARD_TYPES.PIPELINE } });
    });

    it('does not display on the pipeline dashboard', () => {
      expect(findActivityFilter().exists()).toBe(false);
    });
  });

  describe('scanner filter', () => {
    it.each`
      type        | dashboardType
      ${'vendor'} | ${DASHBOARD_TYPES.PROJECT}
      ${'simple'} | ${DASHBOARD_TYPES.GROUP}
      ${'simple'} | ${DASHBOARD_TYPES.INSTANCE}
      ${'simple'} | ${DASHBOARD_TYPES.PIPELINE}
    `('shows the $type scanner filter on the $dashboardType report', ({ type, dashboardType }) => {
      wrapper = createComponent({ provide: { dashboardType } });

      expect(findSimpleScannerFilter().exists()).toBe(type === 'simple');
      expect(findVendorScannerFilter().exists()).toBe(type === 'vendor');
    });
  });
});
