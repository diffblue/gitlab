import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GeoSiteDetails from 'ee/geo_sites/components/details/geo_site_details.vue';
import GeoSites from 'ee/geo_sites/components/geo_sites.vue';
import GeoSiteHeader from 'ee/geo_sites/components/header/geo_site_header.vue';
import { MOCK_PRIMARY_SITE } from '../mock_data';

describe('GeoSites', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
  };

  const createComponent = (props) => {
    wrapper = shallowMount(GeoSites, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGeoSiteHeader = () => wrapper.findComponent(GeoSiteHeader);
  const findGeoSiteDetails = () => wrapper.findComponent(GeoSiteDetails);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the Geo Site Header always', () => {
      expect(findGeoSiteHeader().exists()).toBe(true);
    });

    describe('Site Details', () => {
      it('renders by default', () => {
        expect(findGeoSiteDetails().exists()).toBe(true);
      });

      it('is hidden when toggled', async () => {
        findGeoSiteHeader().vm.$emit('collapse');

        await nextTick();
        expect(findGeoSiteDetails().exists()).toBe(false);
      });
    });
  });
});
