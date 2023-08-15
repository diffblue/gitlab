import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = (initialState = {}) => ({
  state: createState(initialState),
  actions,
  getters,
  mutations,
});

export default (initialState = {}) => new Vuex.Store(getStoreConfig(initialState));
