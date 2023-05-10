import { GlCard } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GeoSiteReplicationCounts from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_counts.vue';
import GeoSiteReplicationStatus from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_status.vue';
import GeoSiteReplicationSummary from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_summary.vue';
import GeoSiteSyncSettings from 'ee/geo_sites/components/details/secondary_site/geo_site_sync_settings.vue';
import { MOCK_SECONDARY_SITE } from 'ee_jest/geo_sites/mock_data';

describe('GeoSiteReplicationSummary', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_SECONDARY_SITE,
  };

  const createComponent = (props) => {
    wrapper = shallowMount(GeoSiteReplicationSummary, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlCard },
    });
  };

  const findGeoSiteReplicationStatus = () => wrapper.findComponent(GeoSiteReplicationStatus);
  const findGeoSiteReplicationCounts = () => wrapper.findComponent(GeoSiteReplicationCounts);
  const findGeoSiteSyncSettings = () => wrapper.findComponent(GeoSiteSyncSettings);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the geo site replication status', () => {
      expect(findGeoSiteReplicationStatus().exists()).toBe(true);
    });

    it('renders the geo site replication counts', () => {
      expect(findGeoSiteReplicationCounts().exists()).toBe(true);
    });

    it('renders the geo site sync settings', () => {
      expect(findGeoSiteSyncSettings().exists()).toBe(true);
    });
  });
});
