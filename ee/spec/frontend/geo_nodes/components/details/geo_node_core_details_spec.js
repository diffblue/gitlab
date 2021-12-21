import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeCoreDetails from 'ee/geo_nodes/components/details/geo_node_core_details.vue';
import {
  MOCK_PRIMARY_VERSION,
  MOCK_REPLICABLE_TYPES,
  MOCK_NODES,
} from 'ee_jest/geo_nodes/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(Vuex);

describe('GeoNodeCoreDetails', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_NODES[0],
  };

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        primaryVersion: MOCK_PRIMARY_VERSION.version,
        primaryRevision: MOCK_PRIMARY_VERSION.revision,
        replicableTypes: MOCK_REPLICABLE_TYPES,
        ...initialState,
      },
    });

    wrapper = extendedWrapper(
      shallowMount(GeoNodeCoreDetails, {
        store,
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findNodeUrl = () => wrapper.findComponent(GlLink);
  const findNodeInternalUrl = () => wrapper.findByTestId('node-internal-url');
  const findNodeVersion = () => wrapper.findByTestId('node-version');

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the Node Url correctly', () => {
        expect(findNodeUrl().exists()).toBe(true);
        expect(findNodeUrl().attributes('href')).toBe(MOCK_NODES[0].url);
        expect(findNodeUrl().attributes('target')).toBe('_blank');
        expect(findNodeUrl().text()).toBe(MOCK_NODES[0].url);
      });

      it('renders the node version', () => {
        expect(findNodeVersion().exists()).toBe(true);
      });
    });

    describe.each`
      node
      ${MOCK_NODES[0]}
      ${MOCK_NODES[1]}
    `('internal URL', ({ node }) => {
      beforeEach(() => {
        createComponent(null, { node });
      });

      describe(`when primary is ${node.primary}`, () => {
        it(`does render node internal url`, () => {
          expect(findNodeInternalUrl().exists()).toBe(true);
        });
      });
    });

    describe('node version', () => {
      describe.each`
        currentNode                                                                           | versionText                                                             | versionMismatch
        ${{ version: MOCK_PRIMARY_VERSION.version, revision: MOCK_PRIMARY_VERSION.revision }} | ${`${MOCK_PRIMARY_VERSION.version} (${MOCK_PRIMARY_VERSION.revision})`} | ${false}
        ${{ version: 'asdf', revision: MOCK_PRIMARY_VERSION.revision }}                       | ${`asdf (${MOCK_PRIMARY_VERSION.revision})`}                            | ${true}
        ${{ version: MOCK_PRIMARY_VERSION.version, revision: 'asdf' }}                        | ${`${MOCK_PRIMARY_VERSION.version} (asdf)`}                             | ${true}
        ${{ version: null, revision: null }}                                                  | ${'Unknown'}                                                            | ${true}
      `(`conditionally`, ({ currentNode, versionText, versionMismatch }) => {
        beforeEach(() => {
          createComponent(null, { node: { ...MOCK_NODES[0], ...currentNode } });
        });

        describe(`when version mismatch is ${versionMismatch} and current node version is ${versionText}`, () => {
          it(`does ${versionMismatch ? '' : 'not '}render version with error color`, () => {
            expect(findNodeVersion().classes('gl-text-red-500')).toBe(versionMismatch);
          });

          it('does render version text correctly', () => {
            expect(findNodeVersion().text()).toBe(versionText);
          });
        });
      });
    });
  });
});
