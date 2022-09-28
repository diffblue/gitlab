import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeReplicationCounts from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_counts.vue';
import GeoNodeReplicationSyncPercentage from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_sync_percentage.vue';
import { MOCK_SECONDARY_NODE, MOCK_REPLICATION_COUNTS } from 'ee_jest/geo_nodes/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

Vue.use(Vuex);

describe('GeoNodeReplicationCounts', () => {
  let wrapper;

  const defaultProps = {
    nodeId: MOCK_SECONDARY_NODE.id,
  };

  const createComponent = (props, getters) => {
    const store = new Vuex.Store({
      getters: {
        replicationCountsByDataTypeForNode: () => () => MOCK_REPLICATION_COUNTS,
        ...getters,
      },
    });

    wrapper = extendedWrapper(
      shallowMount(GeoNodeReplicationCounts, {
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

  const findReplicationTypeSections = () => wrapper.findAllByTestId('replication-type');
  const findReplicationTypeSectionTitles = () =>
    findReplicationTypeSections().wrappers.map((w) => w.text());
  const findGeoNodeReplicationSyncPercentage = () =>
    wrapper.findAllComponents(GeoNodeReplicationSyncPercentage);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a replication type section for each entry in the replication counts array', () => {
      expect(findReplicationTypeSections()).toHaveLength(MOCK_REPLICATION_COUNTS.length);
      expect(findReplicationTypeSectionTitles()).toStrictEqual(
        MOCK_REPLICATION_COUNTS.map(({ title }) => title),
      );
    });

    it('renders an individual sync and verification section for each entry in the replication counts array', () => {
      expect(findGeoNodeReplicationSyncPercentage()).toHaveLength(
        MOCK_REPLICATION_COUNTS.length * 2,
      );
    });
  });
});
