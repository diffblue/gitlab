import { shallowMount } from '@vue/test-utils';
import GeoNodeProgressBar from 'ee/geo_nodes/components/details/geo_node_progress_bar.vue';
import GeoNodeReplicationStatusMobile from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_status_mobile.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('GeoNodeReplicationStatusMobile', () => {
  let wrapper;

  const defaultProps = {
    item: {
      component: 'Test',
      syncValues: null,
      verificationValues: null,
    },
    translations: {
      nA: 'N/A',
      progressBarSyncTitle: '%{component} synced',
      progressBarVerifTitle: '%{component} verified',
    },
  };

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(GeoNodeReplicationStatusMobile, {
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
        expect(findItemSyncStatus().findComponent(GeoNodeProgressBar).exists()).toBe(
          renderSyncProgress,
        );
        expect(extendedWrapper(findItemSyncStatus()).findByText('N/A').exists()).toBe(
          !renderSyncProgress,
        );
      });

      it('renders verification progress correctly', () => {
        expect(findItemVerificationStatus().findComponent(GeoNodeProgressBar).exists()).toBe(
          renderVerifProgress,
        );
        expect(extendedWrapper(findItemVerificationStatus()).findByText('N/A').exists()).toBe(
          !renderVerifProgress,
        );
      });
    });
  });
});
