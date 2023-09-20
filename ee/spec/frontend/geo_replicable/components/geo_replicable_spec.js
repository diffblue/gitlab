import { GlKeysetPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import initStore from 'ee/geo_replicable/store';
import { PREV, NEXT } from 'ee/geo_replicable/constants';

import * as types from 'ee/geo_replicable/store/mutation_types';
import {
  MOCK_BASIC_GRAPHQL_DATA,
  MOCK_REPLICABLE_TYPE,
  MOCK_GRAPHQL_PAGINATION_DATA,
} from '../mock_data';

Vue.use(Vuex);

describe('GeoReplicable', () => {
  let wrapper;
  let store;

  const createStore = (options) => {
    store = initStore({
      replicableType: MOCK_REPLICABLE_TYPE,
      ...options,
    });
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
  const findGlKeysetPagination = () =>
    findGeoReplicableContainer().findComponent(GlKeysetPagination);
  const findGeoReplicableItem = () =>
    findGeoReplicableContainer().findAllComponents(GeoReplicableItem);

  describe('template', () => {
    beforeEach(() => {
      createStore();
      store.commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, {
        data: MOCK_BASIC_GRAPHQL_DATA,
        pagination: MOCK_GRAPHQL_PAGINATION_DATA,
      });
      createComponent();
    });

    it('renders the replicable container', () => {
      expect(findGeoReplicableContainer().exists()).toBe(true);
    });

    it('renders an instance for each replicableItem in the store', () => {
      const replicableItemWrappers = findGeoReplicableItem();
      const replicableItems = [...store.state.replicableItems];

      for (let i = 0; i < replicableItemWrappers.length; i += 1) {
        expect(replicableItemWrappers.at(i).props().registryId).toBe(replicableItems[i].id);
      }
    });

    it('GlKeysetPagination renders', () => {
      createComponent();
      expect(findGlKeysetPagination().exists()).toBe(true);
    });
  });

  describe('changing the page', () => {
    beforeEach(() => {
      createStore();
      store.commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, {
        data: MOCK_BASIC_GRAPHQL_DATA,
        pagination: MOCK_GRAPHQL_PAGINATION_DATA,
      });
      createComponent();
    });

    it('to previous page calls fetchReplicableItems with PREV', () => {
      findGlKeysetPagination().vm.$emit('prev');

      expect(store.dispatch).toHaveBeenCalledWith('fetchReplicableItems', PREV);
    });

    it('to next page calls fetchReplicableItems with NEXT', () => {
      findGlKeysetPagination().vm.$emit('next');

      expect(store.dispatch).toHaveBeenCalledWith('fetchReplicableItems', NEXT);
    });
  });
});
