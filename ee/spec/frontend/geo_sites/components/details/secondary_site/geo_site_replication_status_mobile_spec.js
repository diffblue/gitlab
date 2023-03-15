import { shallowMountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import GeoSiteProgressBar from 'ee/geo_sites/components/details/geo_site_progress_bar.vue';
import GeoSiteReplicationStatusMobile from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_status_mobile.vue';

describe('GeoSiteReplicationStatusMobile', () => {
  let wrapper;

  const defaultProps = {
    item: {
      component: 'Test',
      syncValues: null,
      verificationValues: null,
    },
    translations: {
      nA: 'Not applicable.',
      progressBarSyncTitle: '%{component} synced',
      progressBarVerifTitle: '%{component} verified',
    },
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoSiteReplicationStatusMobile, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findItemSyncStatus = () => wrapper.findByTestId('sync-status');
  const findItemVerificationStatus = () => wrapper.findByTestId('verification-status');

  describe('template', () => {
    describe.each`
      description                    | item                                                                                                                       | renderSyncProgress | renderVerifProgress
      ${'with no data'}              | ${{ component: 'Test Component', syncValues: null, verificationValues: null }}                                             | ${false}           | ${false}
      ${'with no verification data'} | ${{ component: 'Test Component', syncValues: { total: 100, success: 0 }, verificationValues: null }}                       | ${true}            | ${false}
      ${'with no sync data'}         | ${{ component: 'Test Component', syncValues: null, verificationValues: { total: 50, success: 50 } }}                       | ${false}           | ${true}
      ${'with all data'}             | ${{ component: 'Test Component', syncValues: { total: 100, success: 0 }, verificationValues: { total: 50, success: 50 } }} | ${true}            | ${true}
    `('$description', ({ item, renderSyncProgress, renderVerifProgress }) => {
      beforeEach(() => {
        createComponent({ item });
      });

      it('renders sync progress correctly', () => {
        expect(findItemSyncStatus().findComponent(GeoSiteProgressBar).exists()).toBe(
          renderSyncProgress,
        );
        expect(extendedWrapper(findItemSyncStatus()).findByText('Not applicable.').exists()).toBe(
          !renderSyncProgress,
        );
      });

      it('renders verification progress correctly', () => {
        expect(findItemVerificationStatus().findComponent(GeoSiteProgressBar).exists()).toBe(
          renderVerifProgress,
        );
        expect(
          extendedWrapper(findItemVerificationStatus()).findByText('Not applicable.').exists(),
        ).toBe(!renderVerifProgress);
      });
    });
  });
});
