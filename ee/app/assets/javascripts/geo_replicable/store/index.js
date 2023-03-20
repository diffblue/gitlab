import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({
  replicableType,
  graphqlFieldName,
  verificationEnabled,
  geoCurrentSiteId,
  geoTargetSiteId,
}) => ({
  actions,
  getters,
  mutations,
  state: createState({
    replicableType,
    graphqlFieldName,
    verificationEnabled,
    geoCurrentSiteId,
    geoTargetSiteId,
  }),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
