import Vue from 'vue';
import Vuex from 'vuex';
import { setupStore } from 'ee/security_dashboard/store/index';
import {
  SET_FILTER,
  SET_HIDE_DISMISSED,
} from 'ee/security_dashboard/store/modules/filters/mutation_types';

Vue.use(Vuex);

function expectRefreshDispatches(store, payload) {
  expect(store.dispatch).toHaveBeenCalledTimes(1);
  expect(store.dispatch).toHaveBeenCalledWith('vulnerabilities/fetchVulnerabilities', payload);
}

describe('mediator', () => {
  let store;

  beforeEach(() => {
    store = new Vuex.Store();
    setupStore(store);
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
  });

  it('triggers fetching vulnerabilities after one filter changes', () => {
    store.commit(`filters/${SET_FILTER}`, {});

    expectRefreshDispatches(store, store.state.filters.filters);
  });

  it('triggers fetching vulnerabilities after multiple filters change', () => {
    const filters = {
      filter1: ['abc', 'def'],
      filter2: ['123', '456'],
    };
    store.commit(`filters/${SET_FILTER}`, filters);

    expectRefreshDispatches(store, expect.objectContaining(filters));
  });

  it('triggers fetching vulnerabilities after "Hide dismissed" toggle changes', () => {
    store.commit(`filters/${SET_HIDE_DISMISSED}`);

    expectRefreshDispatches(store, store.state.filters.filters);
  });
});
