import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export default ({ licenseRemovalPath, subscriptionSyncPath }) =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state: createState({ licenseRemovalPath, subscriptionSyncPath }),
  });
