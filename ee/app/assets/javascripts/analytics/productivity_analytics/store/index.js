import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import charts from './modules/charts/index';
import filters from './modules/filters/index';
import table from './modules/table/index';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export const getStoreConfig = () => ({
  state: state(),
  getters,
  actions,
  mutations,
  modules: {
    filters,
    charts,
    table,
  },
});

export default new Vuex.Store(getStoreConfig());
