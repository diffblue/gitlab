import { GlIcon, GlSearchBoxByType, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoSiteFormNamespaces from 'ee/geo_site_form/components/geo_site_form_namespaces.vue';
import { MOCK_SYNC_NAMESPACES } from '../mock_data';

Vue.use(Vuex);

describe('GeoSiteFormNamespaces', () => {
  let wrapper;

  const defaultProps = {
    selectedNamespaces: [],
  };

  const actionSpies = {
    fetchSyncNamespaces: jest.fn(),
    toggleNamespace: jest.fn(),
    isSelected: jest.fn(),
  };

  const createComponent = (props = {}, initialState) => {
    const fakeStore = new Vuex.Store({
      state: {
        synchronizationNamespaces: [],
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GeoSiteFormNamespaces, {
      store: fakeStore,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findGlDropdownSearch = () => findGlDropdown().findComponent(GlSearchBoxByType);
  const findDropdownItems = () => findGlDropdown().findAll('button');
  const findDropdownItemsText = () => findDropdownItems().wrappers.map((w) => w.text());
  const findGlIcons = () => wrapper.findAllComponents(GlIcon);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlDropdown', () => {
      expect(findGlDropdown().exists()).toBe(true);
    });

    describe('findGlDropdownSearch', () => {
      it('renders always', () => {
        expect(findGlDropdownSearch().exists()).toBe(true);
      });

      it('has debounce prop', () => {
        expect(findGlDropdownSearch().attributes('debounce')).toBe('500');
      });

      describe('onSearch', () => {
        const namespaceSearch = 'test search';

        beforeEach(() => {
          findGlDropdownSearch().vm.$emit('input', namespaceSearch);
        });

        it('calls fetchSyncNamespaces when input event is fired from GlSearchBoxByType', () => {
          expect(actionSpies.fetchSyncNamespaces).toHaveBeenCalledWith(
            expect.any(Object),
            namespaceSearch,
          );
        });
      });
    });

    describe('findDropdownItems', () => {
      beforeEach(() => {
        createComponent(
          { selectedNamespaces: [[MOCK_SYNC_NAMESPACES[0].id]] },
          { synchronizationNamespaces: MOCK_SYNC_NAMESPACES },
        );
      });

      it('renders an instance for each namespace', () => {
        expect(findDropdownItemsText()).toStrictEqual(MOCK_SYNC_NAMESPACES.map((n) => n.name));
      });

      it('hides GlIcon if namespace not in selectedNamespaces', () => {
        expect(findGlIcons().wrappers.every((w) => w.classes('gl-visibility-hidden'))).toBe(true);
      });
    });
  });

  describe('methods', () => {
    describe('toggleNamespace', () => {
      beforeEach(() => {
        createComponent(
          { selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id] },
          { synchronizationNamespaces: MOCK_SYNC_NAMESPACES },
        );
      });

      describe('when namespace is in selectedNamespaces', () => {
        it('emits `removeSyncOption`', () => {
          wrapper.vm.toggleNamespace(MOCK_SYNC_NAMESPACES[0]);
          expect(wrapper.emitted()).toHaveProperty('removeSyncOption');
        });
      });

      describe('when namespace is not in selectedNamespaces', () => {
        it('emits `addSyncOption`', () => {
          wrapper.vm.toggleNamespace(MOCK_SYNC_NAMESPACES[1]);
          expect(wrapper.emitted()).toHaveProperty('addSyncOption');
        });
      });
    });

    describe('isSelected', () => {
      beforeEach(() => {
        createComponent(
          { selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id] },
          { synchronizationNamespaces: MOCK_SYNC_NAMESPACES },
        );
      });

      describe('when namespace is in selectedNamespaces', () => {
        it('returns `true`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_NAMESPACES[0])).toBe(true);
        });
      });

      describe('when namespace is not in selectedNamespaces', () => {
        it('returns `false`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_NAMESPACES[1])).toBe(false);
        });
      });
    });

    describe('computed', () => {
      describe('dropdownTitle', () => {
        describe('when selectedNamespaces is empty', () => {
          beforeEach(() => {
            createComponent({
              selectedNamespaces: [],
            });
          });

          it('returns `Select groups to replicate`', () => {
            expect(wrapper.vm.dropdownTitle).toBe(
              GeoSiteFormNamespaces.i18n.noSelectedDropdownTitle,
            );
          });
        });

        describe('when selectedNamespaces length === 1', () => {
          beforeEach(() => {
            createComponent({
              selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id],
            });
          });

          it('returns `this.selectedNamespaces.length` group selected', () => {
            expect(wrapper.vm.dropdownTitle).toBe(
              `${wrapper.vm.selectedNamespaces.length} group selected`,
            );
          });
        });

        describe('when selectedNamespaces length > 1', () => {
          beforeEach(() => {
            createComponent({
              selectedNamespaces: [MOCK_SYNC_NAMESPACES[0].id, MOCK_SYNC_NAMESPACES[1].id],
            });
          });

          it('returns `this.selectedNamespaces.length` group selected', () => {
            expect(wrapper.vm.dropdownTitle).toBe(
              `${wrapper.vm.selectedNamespaces.length} groups selected`,
            );
          });
        });
      });

      describe('noSyncNamespaces', () => {
        describe('when synchronizationNamespaces.length > 0', () => {
          beforeEach(() => {
            createComponent({}, { synchronizationNamespaces: MOCK_SYNC_NAMESPACES });
          });

          it('returns `false`', () => {
            expect(wrapper.vm.noSyncNamespaces).toBe(false);
          });
        });
      });

      describe('when synchronizationNamespaces.length === 0', () => {
        beforeEach(() => {
          createComponent();
        });

        it('returns `true`', () => {
          expect(wrapper.vm.noSyncNamespaces).toBe(true);
        });
      });
    });
  });
});
