import { GlTabs, GlTab, GlSearchBoxByType } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import GeoSitesFilters from 'ee/geo_sites/components/geo_sites_filters.vue';
import { HEALTH_STATUS_UI, STATUS_FILTER_QUERY_PARAM } from 'ee/geo_sites/constants';
import * as urlUtils from '~/lib/utils/url_utility';

Vue.use(Vuex);

const MOCK_TAB_COUNT = 5;
const MOCK_SEARCH = 'test search';

describe('GeoSitesFilters', () => {
  let wrapper;
  let store;

  const defaultProps = {
    totalSites: MOCK_TAB_COUNT,
  };

  const actionSpies = {
    setStatusFilter: jest.fn(),
    setSearchFilter: jest.fn(),
  };

  const createComponent = (initialState, props, getters) => {
    store = new Vuex.Store({
      state: {
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        countSitesForStatus: () => () => 0,
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoSitesFilters, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlTab },
    });
  };

  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findAllGlTabs = () => wrapper.findAllComponents(GlTab);
  const findAllGlTabTitles = () => wrapper.findAllComponents(GlTab).wrappers.map((w) => w.text());
  const findAllTab = () => findAllGlTabs().at(0);
  const findGlSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the GlTabs', () => {
        expect(findGlTabs().exists()).toBe(true);
      });

      it('allows GlTabs to manage the query param', () => {
        expect(findGlTabs().attributes('syncactivetabwithqueryparams')).toBe('true');
        expect(findGlTabs().attributes('queryparamname')).toBe(STATUS_FILTER_QUERY_PARAM);
      });

      it('renders the All tab with the totalSites count', () => {
        expect(findAllTab().exists()).toBe(true);
        expect(findAllTab().text()).toBe(`All ${MOCK_TAB_COUNT}`);
      });

      it('renders the GlSearchBox', () => {
        expect(findGlSearchBox().exists()).toBe(true);
      });
    });

    describe('conditional tabs', () => {
      describe('when every status has counts', () => {
        beforeEach(() => {
          createComponent(
            null,
            { totalSites: MOCK_TAB_COUNT },
            { countSitesForStatus: () => () => MOCK_TAB_COUNT },
          );
        });

        it('renders every status tab', () => {
          const expectedTabTitles = [
            `All ${MOCK_TAB_COUNT}`,
            ...Object.values(HEALTH_STATUS_UI).map((tab) => `${tab.text} ${MOCK_TAB_COUNT}`),
          ];

          expect(findAllGlTabTitles()).toStrictEqual(expectedTabTitles);
        });
      });

      describe('when only certain statuses have counts', () => {
        const MOCK_COUNTER_GETTER = () => (status) => {
          if (status === 'healthy' || status === 'unhealthy') {
            return MOCK_TAB_COUNT;
          }

          return 0;
        };

        beforeEach(() => {
          createComponent(
            null,
            { totalSites: MOCK_TAB_COUNT },
            { countSitesForStatus: MOCK_COUNTER_GETTER },
          );
        });

        it('renders only those status tabs', () => {
          const expectedTabTitles = [
            `All ${MOCK_TAB_COUNT}`,
            `Healthy ${MOCK_TAB_COUNT}`,
            `Unhealthy ${MOCK_TAB_COUNT}`,
          ];

          expect(findAllGlTabTitles()).toStrictEqual(expectedTabTitles);
        });
      });
    });
  });

  describe('methods', () => {
    describe('when clicking each tab', () => {
      const expectedTabs = [
        { status: null },
        ...Object.keys(HEALTH_STATUS_UI).map((status) => {
          return { status };
        }),
      ];

      beforeEach(() => {
        createComponent(
          null,
          { totalSites: MOCK_TAB_COUNT },
          { countSitesForStatus: () => () => MOCK_TAB_COUNT },
        );
      });

      it('calls setStatusFilter with the correct status', () => {
        for (let i = 0; i < findAllGlTabs().length; i += 1) {
          findGlTabs().vm.$emit('input', i);

          expect(actionSpies.setStatusFilter).toHaveBeenCalledWith(
            expect.any(Object),
            expectedTabs[i].status,
          );
        }
      });
    });

    describe('when searching in searchbox', () => {
      beforeEach(() => {
        createComponent();
        findGlSearchBox().vm.$emit('input', MOCK_SEARCH);
      });

      it('calls setSearchFilter', () => {
        expect(actionSpies.setSearchFilter).toHaveBeenCalledWith(expect.any(Object), MOCK_SEARCH);
      });
    });
  });

  describe('watchers', () => {
    describe('searchFilter', () => {
      beforeEach(() => {
        createComponent({ searchFilter: null });

        jest.spyOn(urlUtils, 'updateHistory');

        store.state.searchFilter = MOCK_SEARCH;
      });

      it('calls urlUtils.updateHistory when updated', () => {
        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          replace: true,
          url: `${TEST_HOST}/?search=test+search`,
        });
      });
    });
  });
});
