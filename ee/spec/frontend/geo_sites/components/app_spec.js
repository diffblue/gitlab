import { GlButton, GlLoadingIcon, GlModal, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import GeoSitesApp from 'ee/geo_sites/components/app.vue';
import GeoSites from 'ee/geo_sites/components/geo_sites.vue';
import GeoSitesEmptyState from 'ee/geo_sites/components/geo_sites_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  MOCK_PRIMARY_SITE,
  MOCK_SECONDARY_SITE,
  MOCK_SITES,
  MOCK_NEW_SITE_URL,
  MOCK_NOT_CONFIGURED_EMPTY_STATE,
  MOCK_NO_RESULTS_EMPTY_STATE,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoSitesApp', () => {
  let wrapper;

  const actionSpies = {
    fetchSites: jest.fn(),
    removeSite: jest.fn(),
    cancelSiteRemoval: jest.fn(),
  };

  const defaultProps = {
    newSiteUrl: MOCK_NEW_SITE_URL,
  };

  const createComponent = (initialState, props, getters) => {
    const store = new Vuex.Store({
      state: {
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        filteredSites: () => [],
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoSitesApp, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlSprintf },
    });
  };

  const findGeoAddSiteButton = () => wrapper.findComponent(GlButton);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGeoEmptyState = () => wrapper.findComponent(GeoSitesEmptyState);
  const findGeoSites = () => wrapper.findAllComponents(GeoSites);
  const findPrimaryGeoSites = () => wrapper.findAllByTestId('primary-sites');
  const findSecondaryGeoSites = () => wrapper.findAllByTestId('secondary-sites');
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findPrimarySiteTitle = () => wrapper.findByText('Primary site');
  const findSecondarySiteTitle = () => wrapper.findByText('Secondary site');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the GlModal', () => {
        expect(findGlModal().exists()).toBe(true);
      });
    });

    describe.each`
      isLoading | sites         | showLoadingIcon | showSites | showEmptyState | showAddButton
      ${true}   | ${[]}         | ${true}         | ${false}  | ${false}       | ${false}
      ${true}   | ${MOCK_SITES} | ${true}         | ${false}  | ${false}       | ${true}
      ${false}  | ${[]}         | ${false}        | ${false}  | ${true}        | ${false}
      ${false}  | ${MOCK_SITES} | ${false}        | ${true}   | ${false}       | ${true}
    `(
      `conditionally`,
      ({ isLoading, sites, showLoadingIcon, showSites, showEmptyState, showAddButton }) => {
        beforeEach(() => {
          createComponent({ isLoading, sites }, null, { filteredSites: () => sites });
        });

        describe(`when isLoading is ${isLoading} & sites length ${sites.length}`, () => {
          it(`does ${showLoadingIcon ? '' : 'not '}render GlLoadingIcon`, () => {
            expect(findGlLoadingIcon().exists()).toBe(showLoadingIcon);
          });

          it(`does ${showSites ? '' : 'not '}render GeoSites`, () => {
            expect(findGeoSites().exists()).toBe(showSites);
          });

          it(`does ${showEmptyState ? '' : 'not '}render EmptyState`, () => {
            expect(findGeoEmptyState().exists()).toBe(showEmptyState);
          });

          it(`does ${showAddButton ? '' : 'not '}render AddSiteButton`, () => {
            expect(findGeoAddSiteButton().exists()).toBe(showAddButton);
          });
        });
      },
    );

    describe('with Geo Sites', () => {
      beforeEach(() => {
        createComponent({ sites: [MOCK_PRIMARY_SITE, MOCK_SECONDARY_SITE] }, null, {
          filteredSites: () => MOCK_SITES,
        });
      });

      it('renders the correct Geo Site component for each site', () => {
        expect(findPrimaryGeoSites()).toHaveLength(1);
        expect(findSecondaryGeoSites()).toHaveLength(1);
      });
    });

    describe.each`
      description                                | sites                    | primaryTitle | secondaryTitle
      ${'with both primary and secondary sites'} | ${MOCK_SITES}            | ${true}      | ${true}
      ${'with only primary sites'}               | ${[MOCK_PRIMARY_SITE]}   | ${true}      | ${false}
      ${'with only secondary sites'}             | ${[MOCK_SECONDARY_SITE]} | ${false}     | ${true}
      ${'with no sites'}                         | ${[]}                    | ${false}     | ${false}
    `('Site Titles', ({ description, sites, primaryTitle, secondaryTitle }) => {
      describe(`${description}`, () => {
        beforeEach(() => {
          createComponent({ sites }, null, { filteredSites: () => sites });
        });

        it(`should ${primaryTitle ? '' : 'not '}render the Primary Site Title`, () => {
          expect(findPrimarySiteTitle().exists()).toBe(primaryTitle);
        });

        it(`should ${secondaryTitle ? '' : 'not '}render the Secondary Site Title`, () => {
          expect(findSecondarySiteTitle().exists()).toBe(secondaryTitle);
        });
      });
    });

    describe('Empty state', () => {
      describe.each`
        description                                                      | sites         | filteredSites          | renderEmptyState | emptyStateProps
        ${'with no sites configured'}                                    | ${[]}         | ${[]}                  | ${true}          | ${MOCK_NOT_CONFIGURED_EMPTY_STATE}
        ${'with sites configured and no user filter'}                    | ${MOCK_SITES} | ${MOCK_SITES}          | ${false}         | ${null}
        ${'with sites configured and user filters returning results'}    | ${MOCK_SITES} | ${[MOCK_PRIMARY_SITE]} | ${false}         | ${null}
        ${'with sites configured and user filters returning no results'} | ${MOCK_SITES} | ${[]}                  | ${true}          | ${MOCK_NO_RESULTS_EMPTY_STATE}
      `('$description', ({ sites, filteredSites, renderEmptyState, emptyStateProps }) => {
        beforeEach(() => {
          createComponent({ sites }, null, { filteredSites: () => filteredSites });
        });

        it(`should ${renderEmptyState ? '' : 'not '}render the Geo Empty State`, () => {
          expect(findGeoEmptyState().exists()).toBe(renderEmptyState);

          if (renderEmptyState) {
            expect(findGeoEmptyState().props()).toStrictEqual(emptyStateProps);
          }
        });
      });
    });
  });

  describe('onCreate', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls fetchSites', () => {
      expect(actionSpies.fetchSites).toHaveBeenCalledTimes(1);
    });
  });

  describe('Modal Events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls removeSite when modal primary button clicked', () => {
      findGlModal().vm.$emit('primary');

      expect(actionSpies.removeSite).toHaveBeenCalled();
    });

    it('calls cancelSiteRemoval when modal cancel button clicked', () => {
      findGlModal().vm.$emit('cancel');

      expect(actionSpies.cancelSiteRemoval).toHaveBeenCalled();
    });
  });
});
