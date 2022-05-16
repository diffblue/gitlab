import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeReplicationCounts from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_counts.vue';
import GeoNodeReplicationSyncPercentage from 'ee/geo_nodes/components/details/secondary_node/geo_node_replication_sync_percentage.vue';
import { REPOSITORY, BLOB } from 'ee/geo_nodes/constants';
import {
  MOCK_SECONDARY_NODE,
  MOCK_SECONDARY_SYNC_INFO,
  MOCK_PRIMARY_VERIFICATION_INFO,
} from 'ee_jest/geo_nodes/mock_data';
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
        syncInfo: () => () => MOCK_SECONDARY_SYNC_INFO,
        verificationInfo: () => () => MOCK_PRIMARY_VERIFICATION_INFO,
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
    describe('always', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders a replication type section for Git and File', () => {
        expect(findReplicationTypeSections()).toHaveLength(2);
        expect(findReplicationTypeSectionTitles()).toStrictEqual(['Git', 'File']);
      });

      it('renders a sync and verification section for Git and File', () => {
        expect(findGeoNodeReplicationSyncPercentage()).toHaveLength(4);
      });
    });

    const mockRepositoryData = { dataType: REPOSITORY, values: { total: 100, success: 0 } };
    const mockBlobData = { dataType: BLOB, values: { total: 100, success: 100 } };
    const mockGitEmptySync = { title: 'Git', sync: [], verification: [] };
    const mockGitSuccess0 = {
      title: 'Git',
      sync: [{ total: 100, success: 0 }],
      verification: [{ total: 100, success: 0 }],
    };

    const mockFileEmptySync = { title: 'File', sync: [], verification: [] };
    const mockFileSync100 = {
      title: 'File',
      sync: [{ total: 100, success: 100 }],
      verification: [{ total: 100, success: 100 }],
    };

    describe.each`
      description            | mockGetterData                        | expectedData
      ${'with no data'}      | ${[]}                                 | ${[mockGitEmptySync, mockFileEmptySync]}
      ${'with no File data'} | ${[mockRepositoryData]}               | ${[mockGitSuccess0, mockFileEmptySync]}
      ${'with no Git data'}  | ${[mockBlobData]}                     | ${[mockGitEmptySync, mockFileSync100]}
      ${'with all data'}     | ${[mockRepositoryData, mockBlobData]} | ${[mockGitSuccess0, mockFileSync100]}
    `('replicationOverview $description', ({ mockGetterData, expectedData }) => {
      beforeEach(() => {
        createComponent(null, {
          syncInfo: () => () => mockGetterData,
          verificationInfo: () => () => mockGetterData,
        });
      });

      it('creates the correct array', () => {
        expect(wrapper.vm.replicationOverview).toStrictEqual(expectedData);
      });
    });
  });
});
