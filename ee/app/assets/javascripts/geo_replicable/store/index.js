import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

Vue.use(Vuex);

export const getStoreConfig = ({
  replicableType,
  graphqlFieldName,
  graphqlMutationRegistryClass,
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
    graphqlMutationRegistryClass,
    verificationEnabled,
    geoCurrentSiteId,
    geoTargetSiteId,
  }),
});

const createStore = (config) => new Vuex.Store(getStoreConfig(config));
export default createStore;
