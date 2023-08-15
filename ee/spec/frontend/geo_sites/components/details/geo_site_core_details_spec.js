import { GlLink } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteCoreDetails from 'ee/geo_sites/components/details/geo_site_core_details.vue';
import { MOCK_PRIMARY_SITE, MOCK_SECONDARY_SITE } from 'ee_jest/geo_sites/mock_data';

Vue.use(Vuex);

describe('GeoSiteCoreDetails', () => {
  let wrapper;

  const defaultProps = {
    site: MOCK_PRIMARY_SITE,
  };

  const defaultGetters = {
    siteHasVersionMismatch: () => () => false,
  };

  const createComponent = (props, getters) => {
    const store = new Vuex.Store({
      getters: {
        ...defaultGetters,
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoSiteCoreDetails, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findSiteUrl = () => wrapper.findComponent(GlLink);
  const findSiteInternalUrl = () => wrapper.findByTestId('site-internal-url');
  const findSiteVersion = () => wrapper.findByTestId('site-version');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the Site Url correctly', () => {
        expect(findSiteUrl().exists()).toBe(true);
        expect(findSiteUrl().attributes('href')).toBe(MOCK_PRIMARY_SITE.url);
        expect(findSiteUrl().attributes('target')).toBe('_blank');
        expect(findSiteUrl().text()).toBe(MOCK_PRIMARY_SITE.url);
      });

      it('renders the site version', () => {
        expect(findSiteVersion().exists()).toBe(true);
      });
    });

    describe.each`
      site
      ${MOCK_PRIMARY_SITE}
      ${MOCK_SECONDARY_SITE}
    `('internal URL', ({ site }) => {
      beforeEach(() => {
        createComponent({ site });
      });

      describe(`when primary is ${site.primary}`, () => {
        it(`does render site internal url`, () => {
          expect(findSiteInternalUrl().exists()).toBe(true);
        });
      });
    });

    describe('site version', () => {
      describe.each`
        currentSite                                                                     | versionText                                                       | versionMismatch
        ${{ version: MOCK_PRIMARY_SITE.version, revision: MOCK_PRIMARY_SITE.revision }} | ${`${MOCK_PRIMARY_SITE.version} (${MOCK_PRIMARY_SITE.revision})`} | ${false}
        ${{ version: 'asdf', revision: MOCK_PRIMARY_SITE.revision }}                    | ${`asdf (${MOCK_PRIMARY_SITE.revision})`}                         | ${true}
        ${{ version: MOCK_PRIMARY_SITE.version, revision: 'asdf' }}                     | ${`${MOCK_PRIMARY_SITE.version} (asdf)`}                          | ${true}
        ${{ version: null, revision: null }}                                            | ${'Unknown'}                                                      | ${true}
      `(`conditionally`, ({ currentSite, versionText, versionMismatch }) => {
        beforeEach(() => {
          createComponent(
            { site: { ...MOCK_PRIMARY_SITE, ...currentSite } },
            { siteHasVersionMismatch: () => () => versionMismatch },
          );
        });

        describe(`when version mismatch is ${versionMismatch} and current site version is ${versionText}`, () => {
          it(`does ${versionMismatch ? '' : 'not '}render version with error color`, () => {
            expect(findSiteVersion().classes('gl-text-red-500')).toBe(versionMismatch);
          });

          it('does render version text correctly', () => {
            expect(findSiteVersion().text()).toBe(versionText);
          });
        });
      });
    });
  });
});
