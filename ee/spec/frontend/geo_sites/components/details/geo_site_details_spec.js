import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteCoreDetails from 'ee/geo_sites/components/details/geo_site_core_details.vue';
import GeoSiteDetails from 'ee/geo_sites/components/details/geo_site_details.vue';
import GeoSitePrimaryOtherInfo from 'ee/geo_sites/components/details/primary_site/geo_site_primary_other_info.vue';
import GeoSiteVerificationInfo from 'ee/geo_sites/components/details/primary_site/geo_site_verification_info.vue';
import GeoSiteReplicationDetails from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_details.vue';
import GeoSiteReplicationSummary from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_summary.vue';
import GeoSiteSecondaryOtherInfo from 'ee/geo_sites/components/details/secondary_site/geo_site_secondary_other_info.vue';
import { MOCK_PRIMARY_SITE, MOCK_SECONDARY_SITE } from 'ee_jest/geo_sites/mock_data';

describe('GeoSiteDetails', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(GeoSiteDetails, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGeoSiteCoreDetails = () => wrapper.findComponent(GeoSiteCoreDetails);
  const findGeoSitePrimaryOtherInfo = () => wrapper.findComponent(GeoSitePrimaryOtherInfo);
  const findGeoSiteVerificationInfo = () => wrapper.findComponent(GeoSiteVerificationInfo);
  const findGeoSiteSecondaryReplicationSummary = () =>
    wrapper.findComponent(GeoSiteReplicationSummary);
  const findGeoSiteSecondaryOtherInfo = () => wrapper.findComponent(GeoSiteSecondaryOtherInfo);
  const findGeoSiteSecondaryReplicationDetails = () =>
    wrapper.findComponent(GeoSiteReplicationDetails);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the Geo Sites Core Details', () => {
        expect(findGeoSiteCoreDetails().exists()).toBe(true);
      });
    });

    describe.each`
      site                   | showPrimaryComponent | showSecondaryComponent
      ${MOCK_PRIMARY_SITE}   | ${true}              | ${false}
      ${MOCK_SECONDARY_SITE} | ${false}             | ${true}
    `(`conditionally`, ({ site, showPrimaryComponent, showSecondaryComponent }) => {
      beforeEach(() => {
        createComponent({ site });
      });

      describe(`when primary is ${site.primary}`, () => {
        it(`does ${showPrimaryComponent ? '' : 'not '}render GeoSitePrimaryOtherInfo`, () => {
          expect(findGeoSitePrimaryOtherInfo().exists()).toBe(showPrimaryComponent);
        });

        it(`does ${showPrimaryComponent ? '' : 'not '}render GeoSiteVerificationInfo`, () => {
          expect(findGeoSiteVerificationInfo().exists()).toBe(showPrimaryComponent);
        });

        it(`does ${
          showSecondaryComponent ? '' : 'not '
        }render GeoSiteSecondaryReplicationSummary`, () => {
          expect(findGeoSiteSecondaryReplicationSummary().exists()).toBe(showSecondaryComponent);
        });

        it(`does ${showSecondaryComponent ? '' : 'not '}render GeoSiteSecondaryOtherInfo`, () => {
          expect(findGeoSiteSecondaryOtherInfo().exists()).toBe(showSecondaryComponent);
        });

        it(`does ${
          showSecondaryComponent ? '' : 'not '
        }render GeoSiteSecondaryReplicationDetails`, () => {
          expect(findGeoSiteSecondaryReplicationDetails().exists()).toBe(showSecondaryComponent);
        });
      });
    });
  });
});
