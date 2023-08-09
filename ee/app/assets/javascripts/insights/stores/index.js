import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import insights from './modules/insights';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      insights: insights(),
    },
  });

export default createStore();
