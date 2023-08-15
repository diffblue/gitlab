import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import filters from '~/vue_shared/components/filtered_search_bar/store/modules/filters';
import * as actions from './actions';
import mergeRequests from './modules/merge_requests/index';

Vue.use(Vuex);

const createStore = () =>
  new Vuex.Store({
    actions,
    modules: {
      filters,
      mergeRequests,
    },
  });

export default createStore();
