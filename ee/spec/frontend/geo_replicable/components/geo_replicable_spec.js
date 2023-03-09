import { GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import initStore from 'ee/geo_replicable/store';

import * as types from 'ee/geo_replicable/store/mutation_types';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_REPLICABLE_TYPE,
  MOCK_GRAPHQL_PAGINATION_DATA,
  MOCK_RESTFUL_PAGINATION_DATA,
  MOCK_GRAPHQL_REGISTRY,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicable', () => {
  let wrapper;
  let store;

  const createStore = (options) => {
    store = initStore({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null, ...options });
    jest.spyOn(store, 'dispatch').mockImplementation();
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoReplicable, {
      store,
    });
  };

  afterEach(() => {
    store = null;
  });

  const findGeoReplicableContainer = () => wrapper.find('section');
  const findGlPagination = () => findGeoReplicableContainer().findComponent(GlPagination);
  const findGeoReplicableItem = () =>
    findGeoReplicableContainer().findAllComponents(GeoReplicableItem);

  describe('template', () => {
    beforeEach(() => {
      createStore();
      store.commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, {
        data: MOCK_BASIC_FETCH_DATA_MAP,
        pagination: MOCK_RESTFUL_PAGINATION_DATA,
      });
      createComponent();
    });

    it('renders the replicable container', () => {
      expect(findGeoReplicableContainer().exists()).toBe(true);
    });

    describe('GeoReplicableItem', () => {
      it('renders an instance for each replicableItem in the store', () => {
        const replicableItemWrappers = findGeoReplicableItem();
        const replicableItems = [...store.state.replicableItems];

        for (let i = 0; i < replicableItemWrappers.length; i += 1) {
          expect(replicableItemWrappers.at(i).props().projectId).toBe(replicableItems[i].projectId);
        }
      });
    });
  });
  describe('GlPagination', () => {
    describe('when graphqlFieldName is not defined', () => {
      it('renders always', () => {
        createStore();
        createComponent();
        expect(findGlPagination().exists()).toBe(true);
      });
    });

    describe('when graphqlFieldName is defined', () => {
      it('renders always', () => {
        createStore({ graphqlFieldName: MOCK_GRAPHQL_REGISTRY });
        createComponent();
        expect(findGlPagination().exists()).toBe(true);
      });
    });
  });

  describe.each`
    graphqlFieldName         | currentPage | newPage | action
    ${null}                  | ${1}        | ${2}    | ${undefined}
    ${null}                  | ${2}        | ${1}    | ${undefined}
    ${MOCK_GRAPHQL_REGISTRY} | ${1}        | ${2}    | ${'next'}
    ${MOCK_GRAPHQL_REGISTRY} | ${2}        | ${1}    | ${'prev'}
  `(`changing the page`, ({ graphqlFieldName, currentPage, newPage, action }) => {
    describe(`when graphqlFieldName is ${graphqlFieldName}`, () => {
      describe(`from ${currentPage} to ${newPage}`, () => {
        beforeEach(() => {
          createStore({ graphqlFieldName });
          store.commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, {
            data: MOCK_BASIC_FETCH_DATA_MAP,
            pagination: { ...MOCK_GRAPHQL_PAGINATION_DATA, page: currentPage },
          });
          createComponent();
          findGlPagination().vm.$emit(GlPagination.model.event, newPage);
        });

        it(`should call setPage with ${newPage}`, () => {
          expect(store.dispatch).toHaveBeenCalledWith('setPage', newPage);
        });

        it(`should call fetchReplicableItems with ${action}`, () => {
          expect(store.dispatch).toHaveBeenCalledWith('fetchReplicableItems', action);
        });
      });
    });
  });
});
