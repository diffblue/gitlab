import { GlFormGroup, GlSprintf, GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoNodeFormNamespaces from 'ee/geo_node_form/components/geo_node_form_namespaces.vue';
import GeoNodeFormSelectiveSync from 'ee/geo_node_form/components/geo_node_form_selective_sync.vue';
import GeoNodeFormShards from 'ee/geo_node_form/components/geo_node_form_shards.vue';
import { SELECTIVE_SYNC_MORE_INFO, OBJECT_STORAGE_MORE_INFO } from 'ee/geo_node_form/constants';
import { MOCK_NODE, MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoNodeFormSelectiveSync', () => {
  let wrapper;

  const defaultProps = {
    nodeData: MOCK_NODE,
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GeoNodeFormSelectiveSync, {
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

  const findGeoNodeFormSyncTypeFormGroup = () => wrapper.findByTestId('selective-sync-form-group');
  const findGeoNodeFormSyncTypePopoverIcon = () =>
    findGeoNodeFormSyncTypeFormGroup().findComponent(GlIcon);
  const findGeoNodeFormSyncTypePopover = () =>
    findGeoNodeFormSyncTypeFormGroup().findComponent(GlPopover);
  const findGeoNodeFormSyncTypePopoverLink = () =>
    findGeoNodeFormSyncTypePopover().findComponent(GlLink);

  const findGeoNodeFormObjectStorageFormGroup = () =>
    wrapper.findByTestId('object-storage-form-group');
  const findGeoNodeFormObjectStoragePopoverIcon = () =>
    findGeoNodeFormObjectStorageFormGroup().findComponent(GlIcon);
  const findGeoNodeFormObjectStoragePopover = () =>
    findGeoNodeFormObjectStorageFormGroup().findComponent(GlPopover);
  const findGeoNodeFormObjectStoragePopoverLink = () =>
    findGeoNodeFormObjectStoragePopover().findComponent(GlLink);

  const findGeoNodeFormSyncTypeField = () => wrapper.find('#node-selective-synchronization-field');
  const findGeoNodeFormNamespacesField = () => wrapper.findComponent(GeoNodeFormNamespaces);
  const findGeoNodeFormShardsField = () => wrapper.findComponent(GeoNodeFormShards);
  const findGeoNodeObjectStorageField = () => wrapper.find('#node-object-storage-field');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
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

    describe('selective sync type popover', () => {
      it('renders the question icon correctly', () => {
        expect(findGeoNodeFormSyncTypePopoverIcon().exists()).toBe(true);
        expect(findGeoNodeFormSyncTypePopoverIcon().props('name')).toBe('question-o');
      });

      it('renders the GlPopover', () => {
        expect(findGeoNodeFormSyncTypePopover().exists()).toBe(true);
        expect(findGeoNodeFormSyncTypePopover().text()).toContain(
          GeoNodeFormSelectiveSync.i18n.selectiveSyncPopoverText,
        );
      });

      it('renders the popover link correctly', () => {
        expect(findGeoNodeFormSyncTypePopoverLink().exists()).toBe(true);
        expect(findGeoNodeFormSyncTypePopoverLink().attributes('href')).toBe(
          SELECTIVE_SYNC_MORE_INFO,
        );
      });
    });

    describe('object storage popover', () => {
      it('renders the question icon correctly', () => {
        expect(findGeoNodeFormObjectStoragePopoverIcon().exists()).toBe(true);
        expect(findGeoNodeFormObjectStoragePopoverIcon().props('name')).toBe('question-o');
      });

      it('renders the GlPopover', () => {
        expect(findGeoNodeFormObjectStoragePopover().exists()).toBe(true);
        expect(findGeoNodeFormObjectStoragePopover().text()).toContain(
          GeoNodeFormSelectiveSync.i18n.objectStorageFieldPopoverText,
        );
      });

      it('renders the popover link correctly', () => {
        expect(findGeoNodeFormObjectStoragePopoverLink().exists()).toBe(true);
        expect(findGeoNodeFormObjectStoragePopoverLink().attributes('href')).toBe(
          OBJECT_STORAGE_MORE_INFO,
        );
      });
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
        expect(wrapper.emitted('addSyncOption')).toHaveLength(1);
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
        expect(wrapper.emitted('removeSyncOption')).toHaveLength(1);
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
          expect(wrapper.vm.selectiveSyncNamespaces).toBe(false);
        });
      });

      describe('when selectiveSyncType is `NAMESPACES`', () => {
        beforeEach(() => {
          factory(MOCK_SELECTIVE_SYNC_TYPES.NAMESPACES.value);
        });

        it('returns `true`', () => {
          expect(wrapper.vm.selectiveSyncNamespaces).toBe(true);
        });
      });
    });

    describe('selectiveSyncShards', () => {
      describe('when selectiveSyncType is not `SHARDS`', () => {
        beforeEach(() => {
          factory(MOCK_SELECTIVE_SYNC_TYPES.ALL.value);
        });

        it('returns `false`', () => {
          expect(wrapper.vm.selectiveSyncShards).toBe(false);
        });
      });

      describe('when selectiveSyncType is `SHARDS`', () => {
        beforeEach(() => {
          factory(MOCK_SELECTIVE_SYNC_TYPES.SHARDS.value);
        });

        it('returns `true`', () => {
          expect(wrapper.vm.selectiveSyncShards).toBe(true);
        });
      });
    });
  });
});
