import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteReplicationCounts from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_counts.vue';
import GeoSiteReplicationSyncPercentage from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_sync_percentage.vue';
import { MOCK_SECONDARY_SITE, MOCK_REPLICATION_COUNTS } from 'ee_jest/geo_sites/mock_data';

Vue.use(Vuex);

describe('GeoSiteReplicationCounts', () => {
  let wrapper;

  const defaultProps = {
    siteId: MOCK_SECONDARY_SITE.id,
  };

  const createComponent = (props, getters) => {
    const store = new Vuex.Store({
      getters: {
        replicationCountsByDataTypeForSite: () => () => MOCK_REPLICATION_COUNTS,
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoSiteReplicationCounts, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findReplicationTypeSections = () => wrapper.findAllByTestId('replication-type');
  const findReplicationTypeSectionTitles = () =>
    findReplicationTypeSections().wrappers.map((w) => w.text());
  const findGeoSiteReplicationSyncPercentage = () =>
    wrapper.findAllComponents(GeoSiteReplicationSyncPercentage);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a replication type section for each entry in the replication counts array', () => {
      expect(findReplicationTypeSections()).toHaveLength(MOCK_REPLICATION_COUNTS.length);
      expect(findReplicationTypeSectionTitles()).toStrictEqual(
        MOCK_REPLICATION_COUNTS.map(({ title }) => title),
      );
    });

    it('renders an individual sync and verification section for each entry in the replication counts array', () => {
      expect(findGeoSiteReplicationSyncPercentage()).toHaveLength(
        MOCK_REPLICATION_COUNTS.length * 2,
      );
    });
  });
});
