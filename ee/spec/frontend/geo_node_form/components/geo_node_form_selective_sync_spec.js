import { GlFormGroup, GlSprintf, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GeoNodeFormNamespaces from 'ee/geo_node_form/components/geo_node_form_namespaces.vue';
import GeoNodeFormSelectiveSync from 'ee/geo_node_form/components/geo_node_form_selective_sync.vue';
import GeoNodeFormShards from 'ee/geo_node_form/components/geo_node_form_shards.vue';
import {
  SELECTIVE_SYNC_MORE_INFO,
  OBJECT_STORAGE_MORE_INFO,
  OBJECT_STORAGE_BETA,
} from 'ee/geo_node_form/constants';
import { MOCK_NODE, MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoNodeFormSelectiveSync', () => {
  let wrapper;

  const defaultProps = {
    nodeData: MOCK_NODE,
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(GeoNodeFormSelectiveSync, {
      stubs: { GlFormGroup, GlSprintf },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormSyncContainer = () =>
    wrapper.findComponent({ ref: 'geoNodeFormSelectiveSyncContainer' });
  const findGeoNodeFormSelectiveSyncMoreInfoLink = () =>
    wrapper.find('[data-testid="selectiveSyncMoreInfo"]');
  const findGeoNodeFormSyncTypeField = () => wrapper.find('#node-selective-synchronization-field');
  const findGeoNodeFormNamespacesField = () => wrapper.findComponent(GeoNodeFormNamespaces);
  const findGeoNodeFormShardsField = () => wrapper.findComponent(GeoNodeFormShards);
  const findGeoNodeObjectStorageField = () => wrapper.find('#node-object-storage-field');
  const findGeoNodeFormObjectStorageMoreInformation = () =>
    wrapper.find('[data-testid="objectStorageMoreInfo"]');
  const findGeoNodeObjectStorageBetaBadge = () => wrapper.findComponent(GlBadge);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders section More Information link correctly', () => {
      expect(findGeoNodeFormSelectiveSyncMoreInfoLink().attributes('href')).toBe(
        SELECTIVE_SYNC_MORE_INFO,
      );
    });

    it('renders Geo Node Form Sync Container', () => {
      expect(findGeoNodeFormSyncContainer().exists()).toBe(true);
    });

    it('renders Geo Node Sync Type Field', () => {
      expect(findGeoNodeFormSyncTypeField().exists()).toBe(true);
    });

    it('renders Geo Node Object Storage Field', () => {
      expect(findGeoNodeObjectStorageField().exists()).toBe(true);
    });

    it('renders Geo Node Form Object Storage More Information link correctly', () => {
      expect(findGeoNodeFormObjectStorageMoreInformation().attributes('href')).toBe(
        OBJECT_STORAGE_MORE_INFO,
      );
    });

    it('renders Geo Node Form Object Beta Badge link correctly', () => {
      expect(findGeoNodeObjectStorageBetaBadge().attributes('href')).toBe(OBJECT_STORAGE_BETA);
    });

    describe.each`
      syncType                                | showNamespaces | showShards
      ${MOCK_SELECTIVE_SYNC_TYPES.ALL}        | ${false}       | ${false}
      ${MOCK_SELECTIVE_SYNC_TYPES.NAMESPACES} | ${true}        | ${false}
      ${MOCK_SELECTIVE_SYNC_TYPES.SHARDS}     | ${false}       | ${true}
    `(`sync type`, ({ syncType, showNamespaces, showShards }) => {
      beforeEach(() => {
        createComponent({
          nodeData: { ...defaultProps.nodeData, selectiveSyncType: syncType.value },
        });
      });

      it(`${showNamespaces ? 'show' : 'hide'} Namespaces Field`, () => {
        expect(findGeoNodeFormNamespacesField().exists()).toBe(showNamespaces);
      });

      it(`${showShards ? 'show' : 'hide'} Shards Field`, () => {
        expect(findGeoNodeFormShardsField().exists()).toBe(showShards);
      });
    });
  });

  describe('methods', () => {
    describe('addSyncOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('emits `addSyncOption`', () => {
        wrapper.vm.addSyncOption({ key: 'selectiveSyncShards', value: MOCK_SYNC_SHARDS[0].value });
        expect(wrapper.emitted('addSyncOption')).toBeTruthy();
      });
    });

    describe('removeSyncOption', () => {
      beforeEach(() => {
        createComponent({
          nodeData: { ...defaultProps.nodeData, selectiveSyncShards: [MOCK_SYNC_SHARDS[0].value] },
        });
      });

      it('should remove value from nodeData', () => {
        wrapper.vm.removeSyncOption({ key: 'selectiveSyncShards', index: 0 });
        expect(wrapper.emitted('removeSyncOption')).toBeTruthy();
      });
    });
  });

  describe('computed', () => {
    const factory = (selectiveSyncType = MOCK_SELECTIVE_SYNC_TYPES.ALL.value) => {
      createComponent({ nodeData: { ...defaultProps.nodeData, selectiveSyncType } });
    };

    describe('selectiveSyncNamespaces', () => {
      describe('when selectiveSyncType is not `NAMESPACES`', () => {
        beforeEach(() => {
          factory();
        });

        it('returns `false`', () => {
          expect(wrapper.vm.selectiveSyncNamespaces).toBeFalsy();
        });
      });

      describe('when selectiveSyncType is `NAMESPACES`', () => {
        beforeEach(() => {
          factory(MOCK_SELECTIVE_SYNC_TYPES.NAMESPACES.value);
        });

        it('returns `true`', () => {
          expect(wrapper.vm.selectiveSyncNamespaces).toBeTruthy();
        });
      });
    });

    describe('selectiveSyncShards', () => {
      describe('when selectiveSyncType is not `SHARDS`', () => {
        beforeEach(() => {
          factory(MOCK_SELECTIVE_SYNC_TYPES.ALL.value);
        });

        it('returns `false`', () => {
          expect(wrapper.vm.selectiveSyncShards).toBeFalsy();
        });
      });

      describe('when selectiveSyncType is `SHARDS`', () => {
        beforeEach(() => {
          factory(MOCK_SELECTIVE_SYNC_TYPES.SHARDS.value);
        });

        it('returns `true`', () => {
          expect(wrapper.vm.selectiveSyncShards).toBeTruthy();
        });
      });
    });
  });
});
