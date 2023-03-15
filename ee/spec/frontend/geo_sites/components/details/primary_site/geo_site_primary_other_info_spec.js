import { GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteProgressBar from 'ee/geo_sites/components/details/geo_site_progress_bar.vue';
import GeoSitePrimaryOtherInfo from 'ee/geo_sites/components/details/primary_site/geo_site_primary_other_info.vue';
import { MOCK_PRIMARY_SITE, MOCK_SECONDARY_SITE } from 'ee_jest/geo_sites/mock_data';
import { numberToHumanSize } from '~/lib/utils/number_utils';

describe('GeoSitePrimaryOtherInfo', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoSitePrimaryOtherInfo, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlCard = () => wrapper.findComponent(GlCard);
  const findGeoSiteProgressBar = () => wrapper.findComponent(GeoSiteProgressBar);
  const findReplicationSlotWAL = () => wrapper.findByTestId('replication-slot-wal');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the details card', () => {
        expect(findGlCard().exists()).toBe(true);
      });

      it('renders the replication slot WAL section', () => {
        expect(findReplicationSlotWAL().exists()).toBe(true);
      });

      it('renders the replicationSlots progress bar', () => {
        expect(findGeoSiteProgressBar().exists()).toBe(true);
      });
    });

    describe('when replicationSlotWAL exists', () => {
      beforeEach(() => {
        createComponent({ site: MOCK_PRIMARY_SITE });
      });

      it('renders the replicationSlotWAL section correctly', () => {
        expect(findReplicationSlotWAL().text()).toBe(
          numberToHumanSize(MOCK_PRIMARY_SITE.replicationSlotsMaxRetainedWalBytes),
        );
      });
    });

    describe('when replicationSlotWAL is 0', () => {
      beforeEach(() => {
        createComponent({ site: { ...MOCK_PRIMARY_SITE, replicationSlotsMaxRetainedWalBytes: 0 } });
      });

      it('renders 0 bytes', () => {
        expect(findReplicationSlotWAL().text()).toBe('0 bytes');
      });
    });

    describe('when replicationSlotWAL is null', () => {
      beforeEach(() => {
        createComponent({ site: MOCK_SECONDARY_SITE });
      });

      it('renders Unknown', () => {
        expect(findReplicationSlotWAL().text()).toBe('Unknown');
      });
    });
  });
});
