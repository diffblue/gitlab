import { GlButton, GlLoadingIcon, GlModal, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodesApp from 'ee/geo_nodes/components/app.vue';
import GeoNodes from 'ee/geo_nodes/components/geo_nodes.vue';
import GeoNodesEmptyState from 'ee/geo_nodes/components/geo_nodes_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  MOCK_PRIMARY_NODE,
  MOCK_SECONDARY_NODE,
  MOCK_NODES,
  MOCK_NEW_NODE_URL,
  MOCK_NOT_CONFIGURED_EMPTY_STATE,
  MOCK_NO_RESULTS_EMPTY_STATE,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoNodesApp', () => {
  let wrapper;

  const actionSpies = {
    fetchNodes: jest.fn(),
    removeNode: jest.fn(),
    cancelNodeRemoval: jest.fn(),
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
        filteredNodes: () => [],
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

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodesAppContainer = () => wrapper.find('section');
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

      it('renders the Geo Nodes App Container', () => {
        expect(findGeoNodesAppContainer().exists()).toBe(true);
      });

      it('renders the GlModal', () => {
        expect(findGlModal().exists()).toBe(true);
      });
    });

    describe.each`
      isLoading | nodes         | showLoadingIcon | showNodes | showEmptyState | showAddButton
      ${true}   | ${[]}         | ${true}         | ${false}  | ${false}       | ${false}
      ${true}   | ${MOCK_NODES} | ${true}         | ${false}  | ${false}       | ${true}
      ${false}  | ${[]}         | ${false}        | ${false}  | ${true}        | ${false}
      ${false}  | ${MOCK_NODES} | ${false}        | ${true}   | ${false}       | ${true}
    `(
      `conditionally`,
      ({ isLoading, nodes, showLoadingIcon, showNodes, showEmptyState, showAddButton }) => {
        beforeEach(() => {
          createComponent({ isLoading, nodes }, null, { filteredNodes: () => nodes });
        });

        describe(`when isLoading is ${isLoading} & nodes length ${nodes.length}`, () => {
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
        createComponent({ nodes: [MOCK_PRIMARY_NODE, MOCK_SECONDARY_NODE] }, null, {
          filteredNodes: () => MOCK_NODES,
        });
      });

      it('renders the correct Geo Node component for each node', () => {
        expect(findPrimaryGeoNodes()).toHaveLength(1);
        expect(findSecondaryGeoNodes()).toHaveLength(1);
      });
    });

    describe.each`
      description                                | nodes                    | primaryTitle | secondaryTitle
      ${'with both primary and secondary nodes'} | ${MOCK_NODES}            | ${true}      | ${true}
      ${'with only primary nodes'}               | ${[MOCK_PRIMARY_NODE]}   | ${true}      | ${false}
      ${'with only secondary nodes'}             | ${[MOCK_SECONDARY_NODE]} | ${false}     | ${true}
      ${'with no nodes'}                         | ${[]}                    | ${false}     | ${false}
    `('Site Titles', ({ description, nodes, primaryTitle, secondaryTitle }) => {
      describe(`${description}`, () => {
        beforeEach(() => {
          createComponent({ nodes }, null, { filteredNodes: () => nodes });
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
        description                                                      | nodes         | filteredNodes          | renderEmptyState | emptyStateProps
        ${'with no nodes configured'}                                    | ${[]}         | ${[]}                  | ${true}          | ${MOCK_NOT_CONFIGURED_EMPTY_STATE}
        ${'with nodes configured and no user filter'}                    | ${MOCK_NODES} | ${MOCK_NODES}          | ${false}         | ${null}
        ${'with nodes configured and user filters returning results'}    | ${MOCK_NODES} | ${[MOCK_PRIMARY_NODE]} | ${false}         | ${null}
        ${'with nodes configured and user filters returning no results'} | ${MOCK_NODES} | ${[]}                  | ${true}          | ${MOCK_NO_RESULTS_EMPTY_STATE}
      `('$description', ({ nodes, filteredNodes, renderEmptyState, emptyStateProps }) => {
        beforeEach(() => {
          createComponent({ nodes }, null, { filteredNodes: () => filteredNodes });
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

    it('calls fetchNodes', () => {
      expect(actionSpies.fetchNodes).toHaveBeenCalledTimes(1);
    });
  });

  describe('Modal Events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls removeNode when modal primary button clicked', () => {
      findGlModal().vm.$emit('primary');

      expect(actionSpies.removeNode).toHaveBeenCalled();
    });

    it('calls cancelNodeRemoval when modal cancel button clicked', () => {
      findGlModal().vm.$emit('cancel');

      expect(actionSpies.cancelNodeRemoval).toHaveBeenCalled();
    });
  });
});
