import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import {
  DEFAULT_SEARCH_DELAY,
  RESYNC_MODAL_ID,
  FILTER_OPTIONS,
  FILTER_STATES,
} from 'ee/geo_replicable/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  MOCK_REPLICABLE_TYPE,
  MOCK_RESTFUL_PAGINATION_DATA,
  MOCK_GRAPHQL_PAGINATION_DATA,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicableFilterBar', () => {
  let wrapper;

  const actionSpies = {
    setSearch: jest.fn(),
    setStatusFilter: jest.fn(),
    fetchReplicableItems: jest.fn(),
    initiateAllReplicableSyncs: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: { ...initialState },
      actions: actionSpies,
      getters: {
        replicableTypeName: () => MOCK_REPLICABLE_TYPE,
      },
    });

    wrapper = shallowMount(GeoReplicableFilterBar, {
      store,
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

  const legacyFilterOptions = FILTER_OPTIONS.filter(
    (option) => option.value !== FILTER_STATES.STARTED.value,
  );

  const getFilterLabels = (filters) => {
    return filters.map((filter) => {
      if (!filter.value) {
        return `${filter.label} ${MOCK_REPLICABLE_TYPE}`;
      }

      return filter.label;
    });
  };

  describe('template', () => {
    describe('when useGraphQl is false', () => {
      beforeEach(() => {
        createComponent({ useGraphQL: false, paginationData: MOCK_RESTFUL_PAGINATION_DATA });
      });

      it('renders the nav container', () => {
        expect(findNavContainer().exists()).toBe(true);
      });

      it('renders the filter dropdown', () => {
        expect(findGlDropdown().exists()).toBe(true);
      });

      it('renders the correct filter options', () => {
        expect(findDropdownItemsText()).toStrictEqual(getFilterLabels(legacyFilterOptions));
      });

      it('renders the search box with debounce prop', () => {
        expect(findGlSearchBox().exists()).toBe(true);
        expect(findGlSearchBox().attributes('debounce')).toBe(DEFAULT_SEARCH_DELAY.toString());
      });

      it('does render Re-sync all button that is bound to GlModal', () => {
        expect(findGlButton().exists()).toBe(true);
        expect(getBinding(findGlButton().element, 'gl-modal-directive').value).toBe(
          RESYNC_MODAL_ID,
        );
      });
    });

    describe('when useGraphQl is true', () => {
      beforeEach(() => {
        createComponent({ useGraphQl: true, paginationData: MOCK_GRAPHQL_PAGINATION_DATA });
      });

      it('renders the nav container', () => {
        expect(findNavContainer().exists()).toBe(true);
      });

      it('renders the filter dropdown', () => {
        expect(findGlDropdown().exists()).toBe(true);
      });

      it('renders the correct filter options', () => {
        expect(findDropdownItemsText()).toStrictEqual(getFilterLabels(FILTER_OPTIONS));
      });

      it('does not render search box', () => {
        expect(findGlSearchBox().exists()).toBe(false);
      });

      it('does not render Re-sync all button', () => {
        expect(findGlButton().exists()).toBe(false);
      });
    });
  });

  describe('Status filter actions', () => {
    beforeEach(() => {
      createComponent({ useGraphQl: true, paginationData: MOCK_GRAPHQL_PAGINATION_DATA });
    });

    it('clicking a filter item calls setStatusFilter with value and fetchReplicableItems', () => {
      const index = 1;
      findGlDropdownItems().at(index).vm.$emit('click');

      expect(actionSpies.setStatusFilter).toHaveBeenCalledWith(
        expect.any(Object),
        FILTER_OPTIONS[index].value,
      );
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });

  describe('Search box actions', () => {
    beforeEach(() => {
      createComponent({ useGraphQl: false, paginationData: MOCK_RESTFUL_PAGINATION_DATA });
    });

    it('searching calls setSearch with search and fetchReplicableItems', () => {
      const testSearch = 'test search';
      findGlSearchBox().vm.$emit('input', testSearch);

      expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), testSearch);
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });

  describe('GlModal', () => {
    describe.each`
      total | title
      ${1}  | ${`Resync all ${MOCK_REPLICABLE_TYPE}`}
      ${15} | ${`Resync all 15 ${MOCK_REPLICABLE_TYPE}`}
    `(`template when total is $total`, ({ total, title }) => {
      beforeEach(() => {
        createComponent({ useGraphQl: false, paginationData: { total } });
      });

      it(`sets the title to ${title}`, () => {
        expect(findGlModal().props('title')).toBe(title);
      });
    });

    describe('actions', () => {
      beforeEach(() => {
        createComponent({ useGraphQl: false, paginationData: MOCK_RESTFUL_PAGINATION_DATA });
      });

      it('calls initiateAllReplicableSyncs when primary action is emitted', () => {
        findGlModal().vm.$emit('primary');

        expect(actionSpies.initiateAllReplicableSyncs).toHaveBeenCalled();
      });
    });
  });
});
