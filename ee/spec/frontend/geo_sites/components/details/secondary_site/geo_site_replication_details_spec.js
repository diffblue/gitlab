import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteReplicationDetails from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_details.vue';
import GeoSiteReplicationDetailsResponsive from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_details_responsive.vue';
import GeoSiteReplicationStatusMobile from 'ee/geo_sites/components/details/secondary_site/geo_site_replication_status_mobile.vue';
import { GEO_REPLICATION_SUPPORTED_TYPES_URL } from 'ee/geo_sites/constants';
import { MOCK_SECONDARY_SITE, MOCK_REPLICABLE_TYPES } from 'ee_jest/geo_sites/mock_data';

Vue.use(Vuex);

describe('GeoSiteReplicationDetails', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_SECONDARY_SITE,
  };

  const createComponent = (initialState, props, getters) => {
    const store = new Vuex.Store({
      state: {
        replicableTypes: MOCK_REPLICABLE_TYPES,
        ...initialState,
      },
      getters: {
        syncInfo: () => () => [],
        verificationInfo: () => () => [],
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoSiteReplicationDetails, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GeoSiteReplicationDetailsResponsive, GlSprintf },
    });
  };

  const findGeoMobileReplicationDetails = () =>
    wrapper.findByTestId('geo-replication-details-mobile');
  const findGeoMobileReplicationStatus = () =>
    findGeoMobileReplicationDetails().findComponent(GeoSiteReplicationStatusMobile);
  const findGeoDesktopReplicationDetails = () =>
    wrapper.findByTestId('geo-replication-details-desktop');
  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findNAVerificationHelpLink = () => wrapper.findByTestId('naVerificationHelpLink');
  const findReplicableComponent = () => wrapper.findByTestId('replicable-component');
  const findReplicableComponentLink = () => findReplicableComponent().findComponent(GlLink);

  describe('template', () => {
    describe('when un-collapsed', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the collapse button correctly', () => {
        expect(findCollapseButton().exists()).toBe(true);
        expect(findCollapseButton().attributes('icon')).toBe('chevron-down');
      });

      it('renders mobile replication details with correct visibility class', () => {
        expect(findGeoMobileReplicationDetails().exists()).toBe(true);
        expect(findGeoMobileReplicationDetails().classes()).toStrictEqual(['gl-md-display-none!']);
      });

      it('renders mobile replication details with mobile component slot', () => {
        expect(findGeoMobileReplicationStatus().exists()).toBe(true);
      });

      it('renders desktop details with correct visibility class', () => {
        expect(findGeoDesktopReplicationDetails().exists()).toBe(true);
        expect(findGeoDesktopReplicationDetails().classes()).toStrictEqual([
          'gl-display-none',
          'gl-md-display-block',
        ]);
      });

      it('renders Not applicable Verification Help Text with correct link', () => {
        expect(findNAVerificationHelpLink().attributes('href')).toBe(
          GEO_REPLICATION_SUPPORTED_TYPES_URL,
        );
      });
    });

    describe('when collapsed', () => {
      beforeEach(() => {
        createComponent();
        findCollapseButton().vm.$emit('click');
      });

      it('renders the collapse button correctly', () => {
        expect(findCollapseButton().exists()).toBe(true);
        expect(findCollapseButton().attributes('icon')).toBe('chevron-right');
      });

      it('does not render mobile replication details', () => {
        expect(findGeoMobileReplicationDetails().exists()).toBe(false);
      });

      it('does not render desktop replication details', () => {
        expect(findGeoDesktopReplicationDetails().exists()).toBe(false);
      });
    });

    const mockSync = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      title: MOCK_REPLICABLE_TYPES[0].titlePlural,
      values: { total: 100, success: 0 },
    };

    const mockVerif = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      title: MOCK_REPLICABLE_TYPES[0].titlePlural,
      values: { total: 50, success: 50 },
    };

    const mockExpectedNoValues = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_SITE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ).toString(),
      syncValues: null,
      verificationValues: null,
    };

    const mockExpectedOnlySync = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_SITE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ).toString(),
      syncValues: { total: 100, success: 0 },
      verificationValues: null,
    };

    const mockExpectedOnlyVerif = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_SITE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ).toString(),
      syncValues: null,
      verificationValues: { total: 50, success: 50 },
    };

    const mockExpectedBothTypes = {
      dataTypeTitle: MOCK_REPLICABLE_TYPES[0].dataTypeTitle,
      component: MOCK_REPLICABLE_TYPES[0].titlePlural,
      replicationView: new URL(
        `${MOCK_SECONDARY_SITE.url}${MOCK_REPLICABLE_TYPES[0].customReplicationUrl}`,
      ).toString(),
      syncValues: { total: 100, success: 0 },
      verificationValues: { total: 50, success: 50 },
    };

    describe.each`
      description                    | mockSyncData  | mockVerificationData | expectedProps              | hasNAVerificationHelpText
      ${'with no data'}              | ${[]}         | ${[]}                | ${[mockExpectedNoValues]}  | ${true}
      ${'with no verification data'} | ${[mockSync]} | ${[]}                | ${[mockExpectedOnlySync]}  | ${true}
      ${'with no sync data'}         | ${[]}         | ${[mockVerif]}       | ${[mockExpectedOnlyVerif]} | ${false}
      ${'with all data'}             | ${[mockSync]} | ${[mockVerif]}       | ${[mockExpectedBothTypes]} | ${false}
    `(
      '$description',
      ({ mockSyncData, mockVerificationData, expectedProps, hasNAVerificationHelpText }) => {
        beforeEach(() => {
          createComponent({ replicableTypes: [MOCK_REPLICABLE_TYPES[0]] }, null, {
            syncInfo: () => () => mockSyncData,
            verificationInfo: () => () => mockVerificationData,
          });
        });

        it('passes the correct props to the mobile replication details', () => {
          expect(findGeoMobileReplicationDetails().props()).toStrictEqual({
            replicationItems: expectedProps,
            siteId: MOCK_SECONDARY_SITE.id,
          });
        });

        it('passes the correct props to the desktop replication details', () => {
          expect(findGeoDesktopReplicationDetails().props()).toStrictEqual({
            replicationItems: expectedProps,
            siteId: MOCK_SECONDARY_SITE.id,
          });
        });

        it(`does ${
          hasNAVerificationHelpText ? '' : 'not '
        }show Not applicable verification help text`, () => {
          expect(findNAVerificationHelpLink().exists()).toBe(hasNAVerificationHelpText);
        });
      },
    );

    describe('component links', () => {
      describe('with noReplicationView', () => {
        beforeEach(() => {
          createComponent({ replicableTypes: [MOCK_REPLICABLE_TYPES[1]] });
        });

        it('renders replicable component title', () => {
          expect(findReplicableComponent().text()).toBe(MOCK_REPLICABLE_TYPES[1].titlePlural);
        });

        it(`does not render GlLink to secondary replication view`, () => {
          expect(findReplicableComponentLink().exists()).toBe(false);
        });
      });
    });

    describe.each`
      description                       | replicableType              | expectedUrl
      ${'with customReplicationUrl'}    | ${MOCK_REPLICABLE_TYPES[2]} | ${`${MOCK_SECONDARY_SITE.url}${MOCK_REPLICABLE_TYPES[2].customReplicationUrl}`}
      ${'without customReplicationUrl'} | ${MOCK_REPLICABLE_TYPES[3]} | ${`${MOCK_SECONDARY_SITE.url}admin/geo/sites/${MOCK_SECONDARY_SITE.id}/replication/${MOCK_REPLICABLE_TYPES[3].namePlural}`}
    `('component links $description', ({ replicableType, expectedUrl }) => {
      beforeEach(() => {
        createComponent({ replicableTypes: [replicableType] });
      });

      it('renders replicable component title', () => {
        expect(findReplicableComponent().text()).toBe(replicableType.titlePlural);
      });

      it(`renders GlLink to secondary replication view`, () => {
        expect(findReplicableComponentLink().exists()).toBe(true);
        expect(findReplicableComponentLink().attributes('href')).toBe(expectedUrl);
      });
    });
  });
});
