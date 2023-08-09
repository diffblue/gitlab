import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import filters from '~/vue_shared/components/filtered_search_bar/store/modules/filters';
import * as actions from './actions';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    actions,
    modules: { filters },
  });
