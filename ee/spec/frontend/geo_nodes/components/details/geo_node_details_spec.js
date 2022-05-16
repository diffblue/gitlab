import { shallowMount } from '@vue/test-utils';
import GeoNodeCoreDetails from 'ee/geo_nodes/components/details/geo_node_core_details.vue';
import GeoNodeDetails from 'ee/geo_nodes/components/details/geo_node_details.vue';
import GeoNodePrimaryOtherInfo from 'ee/geo_nodes/components/details/primary_node/geo_node_primary_other_info.vue';
import GeoNodeVerificationInfo from 'ee/geo_nodes/components/details/primary_node/geo_node_verification_info.vue';
import GeoNodeReplicationDetails from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_details.vue';
import GeoNodeReplicationSummary from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_summary.vue';
import GeoNodeSecondaryOtherInfo from 'ee/geo_nodes/components/details/secondary_node/geo_node_secondary_other_info.vue';
import { MOCK_PRIMARY_NODE, MOCK_SECONDARY_NODE } from 'ee_jest/geo_nodes/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('GeoNodeDetails', () => {
  let wrapper;

  const defaultProps = {
    node: MOCK_PRIMARY_NODE,
  };

  const createComponent = (props) => {
    wrapper = extendedWrapper(
      shallowMount(GeoNodeDetails, {
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

  const findGeoNodeCoreDetails = () => wrapper.findComponent(GeoNodeCoreDetails);
  const findGeoNodePrimaryOtherInfo = () => wrapper.findComponent(GeoNodePrimaryOtherInfo);
  const findGeoNodeVerificationInfo = () => wrapper.findComponent(GeoNodeVerificationInfo);
  const findGeoNodeSecondaryReplicationSummary = () =>
    wrapper.findComponent(GeoNodeReplicationSummary);
  const findGeoNodeSecondaryOtherInfo = () => wrapper.findComponent(GeoNodeSecondaryOtherInfo);
  const findGeoNodeSecondaryReplicationDetails = () =>
    wrapper.findComponent(GeoNodeReplicationDetails);

  describe('template', () => {
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the Geo Nodes Core Details', () => {
        expect(findGeoNodeCoreDetails().exists()).toBe(true);
      });
    });

    describe.each`
      node                   | showPrimaryComponent | showSecondaryComponent
      ${MOCK_PRIMARY_NODE}   | ${true}              | ${false}
      ${MOCK_SECONDARY_NODE} | ${false}             | ${true}
    `(`conditionally`, ({ node, showPrimaryComponent, showSecondaryComponent }) => {
      beforeEach(() => {
        createComponent({ node });
      });

      describe(`when primary is ${node.primary}`, () => {
        it(`does ${showPrimaryComponent ? '' : 'not '}render GeoNodePrimaryOtherInfo`, () => {
          expect(findGeoNodePrimaryOtherInfo().exists()).toBe(showPrimaryComponent);
        });

        it(`does ${showPrimaryComponent ? '' : 'not '}render GeoNodeVerificationInfo`, () => {
          expect(findGeoNodeVerificationInfo().exists()).toBe(showPrimaryComponent);
        });

        it(`does ${
          showSecondaryComponent ? '' : 'not '
        }render GeoNodeSecondaryReplicationSummary`, () => {
          expect(findGeoNodeSecondaryReplicationSummary().exists()).toBe(showSecondaryComponent);
        });

        it(`does ${showSecondaryComponent ? '' : 'not '}render GeoNodeSecondaryOtherInfo`, () => {
          expect(findGeoNodeSecondaryOtherInfo().exists()).toBe(showSecondaryComponent);
        });

        it(`does ${
          showSecondaryComponent ? '' : 'not '
        }render GeoNodeSecondaryReplicationDetails`, () => {
          expect(findGeoNodeSecondaryReplicationDetails().exists()).toBe(showSecondaryComponent);
        });
      });
    });
  });
});
