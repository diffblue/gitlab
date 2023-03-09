import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import { DEFAULT_SEARCH_DELAY, RESYNC_MODAL_ID } from 'ee/geo_replicable/constants';
import { getStoreConfig } from 'ee/geo_replicable/store';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { MOCK_REPLICABLE_TYPE } from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicableFilterBar', () => {
  let wrapper;

  const actionSpies = {
    setSearch: jest.fn(),
    setFilter: jest.fn(),
    fetchReplicableItems: jest.fn(),
    initiateAllReplicableSyncs: jest.fn(),
  };

  const createComponent = () => {
    const fakeStore = new Vuex.Store({
      ...getStoreConfig({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null }),
      actions: actionSpies,
    });
    wrapper = shallowMount(GeoReplicableFilterBar, {
      store: fakeStore,
      directives: {
        GlModalDirective: createMockDirective('gl-modal-directive'),
      },
    });
  };

  const findNavContainer = () => wrapper.find('nav');
  const findGlDropdown = () => findNavContainer().findComponent(GlDropdown);
  const findGlDropdownItems = () => findNavContainer().findAllComponents(GlDropdownItem);
  const findDropdownItemsText = () => findGlDropdownItems().wrappers.map((w) => w.text());
  const findGlSearchBox = () => findNavContainer().findComponent(GlSearchBoxByType);
  const findGlButton = () => findNavContainer().findComponent(GlButton);
  const findGlModal = () => findNavContainer().findComponent(GlModal);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders nav container always', () => {
      expect(findNavContainer().exists()).toBe(true);
    });

    it('renders dropdown always', () => {
      expect(findGlDropdown().exists()).toBe(true);
    });

    describe('Filter options', () => {
      it('renders a dropdown item for each filterOption', () => {
        expect(findDropdownItemsText()).toStrictEqual(
          wrapper.vm.filterOptions.map((n) => {
            if (n.label === 'All') {
              return `${n.label} ${MOCK_REPLICABLE_TYPE}`;
            }

            return n.label;
          }),
        );
      });

      it('clicking a dropdown item calls setFilter with its index', () => {
        const index = 1;
        findGlDropdownItems().at(index).vm.$emit('click');

        expect(actionSpies.setFilter).toHaveBeenCalledWith(expect.any(Object), index);
      });
    });

    describe('Search box', () => {
      it('renders always', () => {
        expect(findGlSearchBox().exists()).toBe(true);
      });

      it('has debounce prop', () => {
        expect(findGlSearchBox().attributes('debounce')).toBe(DEFAULT_SEARCH_DELAY.toString());
      });

      describe('onSearch', () => {
        const testSearch = 'test search';

        beforeEach(() => {
          findGlSearchBox().vm.$emit('input', testSearch);
        });

        it('calls fetchSyncNamespaces when input event is fired from GlSearchBoxByType', () => {
          expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), testSearch);
          expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
        });
      });
    });

    describe('Re-sync all button', () => {
      it('does not render', () => {
        expect(findGlButton().exists()).toBe(false);
      });

      describe('when there are results', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.paginationData.total = 1;
        });

        it('renders', () => {
          expect(findGlButton().exists()).toBe(true);
        });

        it('triggers GlModal', () => {
          const binding = getBinding(findGlButton().element, 'gl-modal-directive');

          expect(binding.value).toBe(RESYNC_MODAL_ID);
        });
      });
    });

    describe('GlModal', () => {
      it('renders always', () => {
        expect(findGlModal().exists()).toBe(true);
      });

      it('updates title', async () => {
        wrapper.vm.$store.state.paginationData.total = 1;
        await nextTick();
        expect(findGlModal().props('title')).toBe('Resync all designs');
        wrapper.vm.$store.state.paginationData.total = 15;
        await nextTick();
        expect(findGlModal().props('title')).toBe('Resync all 15 designs');
      });

      it('calls initiateAllReplicableSyncs when primary action is emitted', () => {
        findGlModal().vm.$emit('primary');
        expect(actionSpies.initiateAllReplicableSyncs).toHaveBeenCalled();
      });
    });
  });

  describe('filterChange', () => {
    const testValue = 2;

    beforeEach(() => {
      createComponent();
      wrapper.vm.filterChange(testValue);
    });

    it('should call setFilter with the filterIndex', () => {
      expect(actionSpies.setFilter).toHaveBeenCalledWith(expect.any(Object), testValue);
    });

    it('should call fetchReplicableItems', () => {
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });
});
