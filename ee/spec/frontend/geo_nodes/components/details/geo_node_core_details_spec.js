import { GlLink } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoNodeCoreDetails from 'ee/geo_nodes/components/details/geo_node_core_details.vue';
import {
  MOCK_REPLICABLE_TYPES,
  MOCK_PRIMARY_SITE,
  MOCK_SECONDARY_SITE,
} from 'ee_jest/geo_nodes/mock_data';

Vue.use(Vuex);

describe('GeoNodeCoreDetails', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_PRIMARY_SITE,
  };

  const defaultGetters = {
    siteHasVersionMismatch: () => () => false,
  };

  const createComponent = (props, getters) => {
    const store = new Vuex.Store({
      state: {
        replicableTypes: MOCK_REPLICABLE_TYPES,
      },
      getters: {
        ...defaultGetters,
        ...getters,
      },
    });

    wrapper = shallowMountExtended(GeoNodeCoreDetails, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

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
        expect(findNodeUrl().attributes('href')).toBe(MOCK_PRIMARY_SITE.url);
        expect(findNodeUrl().attributes('target')).toBe('_blank');
        expect(findNodeUrl().text()).toBe(MOCK_PRIMARY_SITE.url);
      });

      it('renders the node version', () => {
        expect(findNodeVersion().exists()).toBe(true);
      });
    });

    describe.each`
      node
      ${MOCK_PRIMARY_SITE}
      ${MOCK_SECONDARY_SITE}
    `('internal URL', ({ node }) => {
      beforeEach(() => {
        createComponent({ node });
      });

      describe(`when primary is ${node.primary}`, () => {
        it(`does render node internal url`, () => {
          expect(findNodeInternalUrl().exists()).toBe(true);
        });
      });
    });

    describe('node version', () => {
      describe.each`
        currentNode                                                                     | versionText                                                       | versionMismatch
        ${{ version: MOCK_PRIMARY_SITE.version, revision: MOCK_PRIMARY_SITE.revision }} | ${`${MOCK_PRIMARY_SITE.version} (${MOCK_PRIMARY_SITE.revision})`} | ${false}
        ${{ version: 'asdf', revision: MOCK_PRIMARY_SITE.revision }}                    | ${`asdf (${MOCK_PRIMARY_SITE.revision})`}                         | ${true}
        ${{ version: MOCK_PRIMARY_SITE.version, revision: 'asdf' }}                     | ${`${MOCK_PRIMARY_SITE.version} (asdf)`}                          | ${true}
        ${{ version: null, revision: null }}                                            | ${'Unknown'}                                                      | ${true}
      `(`conditionally`, ({ currentNode, versionText, versionMismatch }) => {
        beforeEach(() => {
          createComponent(
            { node: { ...MOCK_PRIMARY_SITE, ...currentNode } },
            { siteHasVersionMismatch: () => () => versionMismatch },
          );
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
