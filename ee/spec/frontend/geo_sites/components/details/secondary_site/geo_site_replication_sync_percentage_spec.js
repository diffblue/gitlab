import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteReplicationSyncPercentage from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_sync_percentage.vue';

describe('GeoSiteReplicationSyncPercentage', () => {
  let wrapper;

  const defaultProps = {
    values: [],
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoSiteReplicationSyncPercentage, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findPercentageIndicator = () => wrapper.findByTestId('geo-sync-percentage-indicator');
  const findPercentage = () => wrapper.findByTestId('geo-sync-percentage');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the percentage indicator', () => {
        expect(findPercentageIndicator().exists()).toBe(true);
      });

      it('renders the percentage number', () => {
        expect(findPercentage().exists()).toBe(true);
      });
    });

    describe.each`
      description               | values                                                        | expectedColor        | expectedText
      ${'with no data'}         | ${[]}                                                         | ${'gl-bg-gray-200'}  | ${'-%'}
      ${'with all success'}     | ${[{ total: 100, success: 100 }]}                             | ${'gl-bg-green-500'} | ${'100%'}
      ${'with all failure'}     | ${[{ total: 100, success: 0 }]}                               | ${'gl-bg-red-500'}   | ${'0%'}
      ${'with multiple data'}   | ${[{ total: 100, success: 100 }, { total: 100, success: 0 }]} | ${'gl-bg-red-500'}   | ${'50%'}
      ${'with malformed data'}  | ${[{ total: null, success: 0 }]}                              | ${'gl-bg-gray-200'}  | ${'-%'}
      ${'with Infinity result'} | ${[{ total: null, success: 1 }]}                              | ${'gl-bg-gray-200'}  | ${'-%'}
      ${'with very small data'} | ${[{ total: 1000, success: 1 }]}                              | ${'gl-bg-red-500'}   | ${'< 1%'}
    `('conditionally $description', ({ values, expectedColor, expectedText }) => {
      beforeEach(() => {
        createComponent({ values });
      });

      it('renders the correct percentage color', () => {
        expect(findPercentageIndicator().classes(expectedColor)).toBe(true);
      });

      it('renders the correct percentage text', () => {
        expect(findPercentage().text()).toBe(expectedText);
      });
    });
  });
});
