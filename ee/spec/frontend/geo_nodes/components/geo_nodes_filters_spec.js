import { GlTabs, GlTab } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoNodesFilters from 'ee/geo_nodes/components/geo_nodes_filters.vue';
import { HEALTH_STATUS_UI, STATUS_FILTER_QUERY_PARAM } from 'ee/geo_nodes/constants';

Vue.use(Vuex);

const MOCK_TAB_COUNT = 5;

describe('GeoNodesFilters', () => {
  let wrapper;

  const defaultProps = {
    totalNodes: MOCK_TAB_COUNT,
  };

  const actionSpies = {
    setStatusFilter: jest.fn(),
  };

  const createComponent = (initialState, props, getters) => {
    const store = new Vuex.Store({
      state: {
        ...initialState,
      },
      actions: actionSpies,
      getters: {
        countNodesForStatus: () => () => 0,
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoNodesFilters, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: { GlTab },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findAllGlTabs = () => wrapper.findAllComponents(GlTab);
  const findAllGlTabTitles = () => wrapper.findAllComponents(GlTab).wrappers.map((w) => w.text());
  const findAllTab = () => findAllGlTabs().at(0);

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

      it('renders the All tab with the totalNodes count', () => {
        expect(findAllTab().exists()).toBe(true);
        expect(findAllTab().text()).toBe(`All ${MOCK_TAB_COUNT}`);
      });
    });

    describe('conditional tabs', () => {
      describe('when every status has counts', () => {
        beforeEach(() => {
          createComponent(
            null,
            { totalNodes: MOCK_TAB_COUNT },
            { countNodesForStatus: () => () => MOCK_TAB_COUNT },
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
            { totalNodes: MOCK_TAB_COUNT },
            { countNodesForStatus: MOCK_COUNTER_GETTER },
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
          { totalNodes: MOCK_TAB_COUNT },
          { countNodesForStatus: () => () => MOCK_TAB_COUNT },
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
  });
});
