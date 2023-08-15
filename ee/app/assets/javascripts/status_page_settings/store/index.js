import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export default (initialState) =>
  new Vuex.Store({
    state: createState(initialState),
    actions,
    mutations,
  });
