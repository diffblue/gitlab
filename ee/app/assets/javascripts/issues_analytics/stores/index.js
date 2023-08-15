import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import issueAnalytics from './modules/issue_analytics';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    modules: {
      issueAnalytics: issueAnalytics(),
    },
  });

export default createStore();
