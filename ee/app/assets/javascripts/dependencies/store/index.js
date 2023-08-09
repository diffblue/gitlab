import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import { DEPENDENCY_LIST_TYPES } from './constants';
import * as getters from './getters';
import listModule from './modules/list';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      [DEPENDENCY_LIST_TYPES.all.namespace]: listModule(),
    },
    actions,
    getters,
    mutations,
    state,
  });
