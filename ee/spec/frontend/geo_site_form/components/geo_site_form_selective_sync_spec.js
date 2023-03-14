import { GlFormGroup, GlSprintf, GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoSiteFormNamespaces from 'ee/geo_site_form/components/geo_site_form_namespaces.vue';
import GeoSiteFormSelectiveSync from 'ee/geo_site_form/components/geo_site_form_selective_sync.vue';
import GeoSiteFormShards from 'ee/geo_site_form/components/geo_site_form_shards.vue';
import { SELECTIVE_SYNC_MORE_INFO, OBJECT_STORAGE_MORE_INFO } from 'ee/geo_site_form/constants';
import { MOCK_SITE, MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoSiteFormSelectiveSync', () => {
  let wrapper;

  const defaultProps = {
    siteData: MOCK_SITE,
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(GeoSiteFormSelectiveSync, {
      stubs: { GlFormGroup, GlSprintf },
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGeoSiteFormSyncContainer = () =>
    wrapper.findComponent({ ref: 'geoSiteFormSelectiveSyncContainer' });
  const findGeoSiteFormSyncTypeFormGroup = () => wrapper.findByTestId('selective-sync-form-group');
  const findGeoSiteFormSyncTypePopoverIcon = () =>
    findGeoSiteFormSyncTypeFormGroup().findComponent(GlIcon);
  const findGeoSiteFormSyncTypePopover = () =>
    findGeoSiteFormSyncTypeFormGroup().findComponent(GlPopover);
  const findGeoSiteFormSyncTypePopoverLink = () =>
    findGeoSiteFormSyncTypePopover().findComponent(GlLink);

  const findGeoSiteFormObjectStorageFormGroup = () =>
    wrapper.findByTestId('object-storage-form-group');
  const findGeoSiteFormObjectStoragePopoverIcon = () =>
    findGeoSiteFormObjectStorageFormGroup().findComponent(GlIcon);
  const findGeoSiteFormObjectStoragePopover = () =>
    findGeoSiteFormObjectStorageFormGroup().findComponent(GlPopover);
  const findGeoSiteFormObjectStoragePopoverLink = () =>
    findGeoSiteFormObjectStoragePopover().findComponent(GlLink);

  const findGeoSiteFormSyncTypeField = () => wrapper.find('#site-selective-synchronization-field');
  const findGeoSiteFormNamespacesField = () => wrapper.findComponent(GeoSiteFormNamespaces);
  const findGeoSiteFormShardsField = () => wrapper.findComponent(GeoSiteFormShards);
  const findGeoSiteObjectStorageField = () => wrapper.find('#site-object-storage-field');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Geo Site Form Sync Container', () => {
      expect(findGeoSiteFormSyncContainer().exists()).toBe(true);
    });

    it('renders Geo Site Sync Type Field', () => {
      expect(findGeoSiteFormSyncTypeField().exists()).toBe(true);
    });

    it('renders Geo Site Object Storage Field', () => {
      expect(findGeoSiteObjectStorageField().exists()).toBe(true);
    });

    describe('selective sync type popover', () => {
      it('renders the question icon correctly', () => {
        expect(findGeoSiteFormSyncTypePopoverIcon().exists()).toBe(true);
        expect(findGeoSiteFormSyncTypePopoverIcon().props('name')).toBe('question-o');
      });

      it('renders the GlPopover', () => {
        expect(findGeoSiteFormSyncTypePopover().exists()).toBe(true);
        expect(findGeoSiteFormSyncTypePopover().text()).toContain(
          GeoSiteFormSelectiveSync.i18n.selectiveSyncPopoverText,
        );
      });

      it('renders the popover link correctly', () => {
        expect(findGeoSiteFormSyncTypePopoverLink().exists()).toBe(true);
        expect(findGeoSiteFormSyncTypePopoverLink().attributes('href')).toBe(
          SELECTIVE_SYNC_MORE_INFO,
        );
      });
    });

    describe('object storage popover', () => {
      it('renders the question icon correctly', () => {
        expect(findGeoSiteFormObjectStoragePopoverIcon().exists()).toBe(true);
        expect(findGeoSiteFormObjectStoragePopoverIcon().props('name')).toBe('question-o');
      });

      it('renders the GlPopover', () => {
        expect(findGeoSiteFormObjectStoragePopover().exists()).toBe(true);
        expect(findGeoSiteFormObjectStoragePopover().text()).toContain(
          GeoSiteFormSelectiveSync.i18n.objectStorageFieldPopoverText,
        );
      });

      it('renders the popover link correctly', () => {
        expect(findGeoSiteFormObjectStoragePopoverLink().exists()).toBe(true);
        expect(findGeoSiteFormObjectStoragePopoverLink().attributes('href')).toBe(
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
          siteData: { ...defaultProps.siteData, selectiveSyncType: syncType.value },
        });
      });

      it(`${showNamespaces ? 'show' : 'hide'} Namespaces Field`, () => {
        expect(findGeoSiteFormNamespacesField().exists()).toBe(showNamespaces);
      });

      it(`${showShards ? 'show' : 'hide'} Shards Field`, () => {
        expect(findGeoSiteFormShardsField().exists()).toBe(showShards);
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
          siteData: { ...defaultProps.siteData, selectiveSyncShards: [MOCK_SYNC_SHARDS[0].value] },
        });
      });

      it('should remove value from siteData', () => {
        wrapper.vm.removeSyncOption({ key: 'selectiveSyncShards', index: 0 });
        expect(wrapper.emitted('removeSyncOption')).toHaveLength(1);
      });
    });
  });

  describe('computed', () => {
    const factory = (selectiveSyncType = MOCK_SELECTIVE_SYNC_TYPES.ALL.value) => {
      createComponent({ siteData: { ...defaultProps.siteData, selectiveSyncType } });
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
