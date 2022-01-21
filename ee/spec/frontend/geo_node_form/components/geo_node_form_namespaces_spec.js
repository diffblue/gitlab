import { GlIcon, GlSearchBoxByType, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoNodeFormNamespaces from 'ee/geo_node_form/components/geo_node_form_namespaces.vue';
import { MOCK_SYNC_NAMESPACES } from '../mock_data';

Vue.use(Vuex);

jest.mock('~/flash');

describe('GeoNodeFormNamespaces', () => {
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

    wrapper = shallowMount(GeoNodeFormNamespaces, {
      store: fakeStore,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownSearch = () => findGlDropdown().find(GlSearchBoxByType);
  const findDropdownItems = () => findGlDropdown().findAll('button');
  const findDropdownItemsText = () => findDropdownItems().wrappers.map((w) => w.text());
  const findGlIcons = () => wrapper.findAll(GlIcon);

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
          expect(wrapper.emitted('removeSyncOption')).toBeTruthy();
        });
      });

      describe('when namespace is not in selectedNamespaces', () => {
        it('emits `addSyncOption`', () => {
          wrapper.vm.toggleNamespace(MOCK_SYNC_NAMESPACES[1]);
          expect(wrapper.emitted('addSyncOption')).toBeTruthy();
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
          expect(wrapper.vm.isSelected(MOCK_SYNC_NAMESPACES[0])).toBeTruthy();
        });
      });

      describe('when namespace is not in selectedNamespaces', () => {
        it('returns `false`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_NAMESPACES[1])).toBeFalsy();
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
            expect(wrapper.vm.dropdownTitle).toBe('Select groups to replicate');
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
            expect(wrapper.vm.noSyncNamespaces).toBeFalsy();
          });
        });
      });

      describe('when synchronizationNamespaces.length === 0', () => {
        beforeEach(() => {
          createComponent();
        });

        it('returns `true`', () => {
          expect(wrapper.vm.noSyncNamespaces).toBeTruthy();
        });
      });
    });
  });
});
