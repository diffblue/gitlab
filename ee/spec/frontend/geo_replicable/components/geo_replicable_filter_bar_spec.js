import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlModal, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import {
  DEFAULT_SEARCH_DELAY,
  FILTER_OPTIONS,
  FILTER_STATES,
  ACTION_TYPES,
} from 'ee/geo_replicable/constants';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { MOCK_REPLICABLE_TYPE, MOCK_BASIC_FETCH_RESPONSE } from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicableFilterBar', () => {
  let wrapper;

  const actionSpies = {
    setSearch: jest.fn(),
    setStatusFilter: jest.fn(),
    fetchReplicableItems: jest.fn(),
    initiateAllReplicableAction: jest.fn(),
  };

  const defaultState = {
    useGraphQl: true,
    replicableItems: MOCK_BASIC_FETCH_RESPONSE.data,
    verificationEnabled: true,
  };

  const createComponent = (initialState = {}, featureFlags = {}) => {
    const store = new Vuex.Store({
      state: { ...defaultState, ...initialState },
      actions: actionSpies,
      getters: {
        replicableTypeName: () => MOCK_REPLICABLE_TYPE,
      },
    });

    wrapper = shallowMountExtended(GeoReplicableFilterBar, {
      store,
      directives: {
        GlModalDirective: createMockDirective('gl-modal-directive'),
      },
      provide: { glFeatures: { ...featureFlags } },
      stubs: { GlModal, GlSprintf },
    });
  };

  const findNavContainer = () => wrapper.find('nav');
  const findGlDropdown = () => findNavContainer().findComponent(GlDropdown);
  const findGlDropdownItems = () => findNavContainer().findAllComponents(GlDropdownItem);
  const findDropdownItemsText = () => findGlDropdownItems().wrappers.map((w) => w.text());
  const findGlSearchBox = () => findNavContainer().findComponent(GlSearchBoxByType);
  const findResyncAllButton = () => wrapper.findByTestId('geo-resync-all');
  const findReverifyAllButton = () => wrapper.findByTestId('geo-reverify-all');
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
        createComponent({ useGraphQl: false });
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
    });

    describe('when useGraphQl is true', () => {
      beforeEach(() => {
        createComponent({ useGraphQl: true });
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
    });

    describe.each`
      useGraphQl | featureFlag | replicableItems                   | verificationEnabled | showResyncAll | showReverifyAll
      ${false}   | ${false}    | ${[]}                             | ${false}            | ${false}      | ${false}
      ${false}   | ${false}    | ${[]}                             | ${true}             | ${false}      | ${false}
      ${false}   | ${false}    | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${false}            | ${true}       | ${false}
      ${false}   | ${false}    | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${true}             | ${true}       | ${false}
      ${false}   | ${true}     | ${[]}                             | ${false}            | ${false}      | ${false}
      ${false}   | ${true}     | ${[]}                             | ${true}             | ${false}      | ${false}
      ${false}   | ${true}     | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${false}            | ${true}       | ${false}
      ${false}   | ${true}     | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${true}             | ${true}       | ${false}
      ${true}    | ${false}    | ${[]}                             | ${false}            | ${false}      | ${false}
      ${true}    | ${false}    | ${[]}                             | ${true}             | ${false}      | ${false}
      ${true}    | ${false}    | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${false}            | ${false}      | ${false}
      ${true}    | ${false}    | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${true}             | ${false}      | ${false}
      ${true}    | ${true}     | ${[]}                             | ${false}            | ${false}      | ${false}
      ${true}    | ${true}     | ${[]}                             | ${true}             | ${false}      | ${false}
      ${true}    | ${true}     | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${false}            | ${true}       | ${false}
      ${true}    | ${true}     | ${MOCK_BASIC_FETCH_RESPONSE.data} | ${true}             | ${true}       | ${true}
    `(
      'Bulk Actions when useGraphQl is $useGraphQl and geoRegistriesUpdateMutation FF is $featureFlag',
      ({
        useGraphQl,
        featureFlag,
        replicableItems,
        verificationEnabled,
        showResyncAll,
        showReverifyAll,
      }) => {
        beforeEach(() => {
          createComponent(
            { useGraphQl, replicableItems, verificationEnabled },
            { geoRegistriesUpdateMutation: featureFlag },
          );
        });

        it(`does ${showResyncAll ? '' : 'not '}render Resync All Button`, () => {
          expect(findResyncAllButton().exists()).toBe(showResyncAll);
        });

        it(`does ${showReverifyAll ? '' : 'not '}render Reverify All Button`, () => {
          expect(findReverifyAllButton().exists()).toBe(showReverifyAll);
        });
      },
    );
  });

  describe('Status filter actions', () => {
    beforeEach(() => {
      createComponent({ useGraphQl: true });
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
      createComponent({ useGraphQl: false });
    });

    it('searching calls setSearch with search and fetchReplicableItems', () => {
      const testSearch = 'test search';
      findGlSearchBox().vm.$emit('input', testSearch);

      expect(actionSpies.setSearch).toHaveBeenCalledWith(expect.any(Object), testSearch);
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });

  describe('Bulk actions modal', () => {
    describe('Resync All', () => {
      beforeEach(() => {
        createComponent({}, { geoRegistriesUpdateMutation: true });
        findResyncAllButton().vm.$emit('click');
      });

      it('properly populates the modal data', () => {
        expect(findGlModal().props('title')).toBe(`Resync all ${MOCK_REPLICABLE_TYPE}`);
        expect(findGlModal().text()).toContain(`This will resync all ${MOCK_REPLICABLE_TYPE}.`);
      });

      it('dispatches initiateAllReplicableAction when confirmed', () => {
        findGlModal().vm.$emit('primary');

        expect(actionSpies.initiateAllReplicableAction).toHaveBeenCalledWith(expect.any(Object), {
          action: ACTION_TYPES.RESYNC_ALL,
        });
      });
    });

    describe('Reverify All', () => {
      beforeEach(() => {
        createComponent({}, { geoRegistriesUpdateMutation: true });
        findReverifyAllButton().vm.$emit('click');
      });

      it('properly populates the modal data', () => {
        expect(findGlModal().props('title')).toBe(`Reverify all ${MOCK_REPLICABLE_TYPE}`);
        expect(findGlModal().text()).toContain(`This will reverify all ${MOCK_REPLICABLE_TYPE}.`);
      });

      it('dispatches initiateAllReplicableAction when confirmed', () => {
        findGlModal().vm.$emit('primary');

        expect(actionSpies.initiateAllReplicableAction).toHaveBeenCalledWith(expect.any(Object), {
          action: ACTION_TYPES.REVERIFY_ALL,
        });
      });
    });
  });
});
