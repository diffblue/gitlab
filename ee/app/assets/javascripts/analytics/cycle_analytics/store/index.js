import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import filters from '~/vue_shared/components/filtered_search_bar/store/modules/filters';
import * as actions from './actions';
import * as getters from './getters';
import durationChart from './modules/duration_chart/index';
import typeOfWork from './modules/type_of_work/index';
import mutations from './mutations';
import state from './state';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state,
    modules: { durationChart, typeOfWork, filters },
  });
