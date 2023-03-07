import { GlButton, GlLoadingIcon, GlModal, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodesApp from 'ee/geo_nodes/components/app.vue';
import GeoNodes from 'ee/geo_nodes/components/geo_nodes.vue';
import GeoNodesEmptyState from 'ee/geo_nodes/components/geo_nodes_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  MOCK_PRIMARY_SITE,
  MOCK_SECONDARY_SITE,
  MOCK_SITES,
  MOCK_NEW_NODE_URL,
  MOCK_NOT_CONFIGURED_EMPTY_STATE,
  MOCK_NO_RESULTS_EMPTY_STATE,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoNodesApp', () => {
  let wrapper;

  const actionSpies = {
    fetchSites: jest.fn(),
    removeSite: jest.fn(),
    cancelSiteRemoval: jest.fn(),
  };

  const defaultProps = {
    newNodeUrl: MOCK_NEW_NODE_URL,
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

    wrapper = shallowMountExtended(GeoNodesApp, {
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
  const findGeoEmptyState = () => wrapper.findComponent(GeoNodesEmptyState);
  const findGeoNodes = () => wrapper.findAllComponents(GeoNodes);
  const findPrimaryGeoNodes = () => wrapper.findAllByTestId('primary-nodes');
  const findSecondaryGeoNodes = () => wrapper.findAllByTestId('secondary-nodes');
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
      isLoading | sites         | showLoadingIcon | showNodes | showEmptyState | showAddButton
      ${true}   | ${[]}         | ${true}         | ${false}  | ${false}       | ${false}
      ${true}   | ${MOCK_SITES} | ${true}         | ${false}  | ${false}       | ${true}
      ${false}  | ${[]}         | ${false}        | ${false}  | ${true}        | ${false}
      ${false}  | ${MOCK_SITES} | ${false}        | ${true}   | ${false}       | ${true}
    `(
      `conditionally`,
      ({ isLoading, sites, showLoadingIcon, showNodes, showEmptyState, showAddButton }) => {
        beforeEach(() => {
          createComponent({ isLoading, sites }, null, { filteredSites: () => sites });
        });

        describe(`when isLoading is ${isLoading} & sites length ${sites.length}`, () => {
          it(`does ${showLoadingIcon ? '' : 'not '}render GlLoadingIcon`, () => {
            expect(findGlLoadingIcon().exists()).toBe(showLoadingIcon);
          });

          it(`does ${showNodes ? '' : 'not '}render GeoNodes`, () => {
            expect(findGeoNodes().exists()).toBe(showNodes);
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

    describe('with Geo Nodes', () => {
      beforeEach(() => {
        createComponent({ sites: [MOCK_PRIMARY_SITE, MOCK_SECONDARY_SITE] }, null, {
          filteredSites: () => MOCK_SITES,
        });
      });

      it('renders the correct Geo Node component for each node', () => {
        expect(findPrimaryGeoNodes()).toHaveLength(1);
        expect(findSecondaryGeoNodes()).toHaveLength(1);
      });
    });

    describe.each`
      description                                | sites                    | primaryTitle | secondaryTitle
      ${'with both primary and secondary nodes'} | ${MOCK_SITES}            | ${true}      | ${true}
      ${'with only primary nodes'}               | ${[MOCK_PRIMARY_SITE]}   | ${true}      | ${false}
      ${'with only secondary nodes'}             | ${[MOCK_SECONDARY_SITE]} | ${false}     | ${true}
      ${'with no nodes'}                         | ${[]}                    | ${false}     | ${false}
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
        ${'with no nodes configured'}                                    | ${[]}         | ${[]}                  | ${true}          | ${MOCK_NOT_CONFIGURED_EMPTY_STATE}
        ${'with nodes configured and no user filter'}                    | ${MOCK_SITES} | ${MOCK_SITES}          | ${false}         | ${null}
        ${'with nodes configured and user filters returning results'}    | ${MOCK_SITES} | ${[MOCK_PRIMARY_SITE]} | ${false}         | ${null}
        ${'with nodes configured and user filters returning no results'} | ${MOCK_SITES} | ${[]}                  | ${true}          | ${MOCK_NO_RESULTS_EMPTY_STATE}
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
