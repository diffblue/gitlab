import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const getStoreConfig = () => ({
  state: state(),
  actions,
  getters,
  mutations,
});

const createStore = () => new Vuex.Store(getStoreConfig());

export default createStore;
