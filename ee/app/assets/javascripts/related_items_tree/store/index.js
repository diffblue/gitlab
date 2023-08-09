// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import getDefaultState from './state';

const createStore = () =>
  new Vuex.Store({
    state: getDefaultState(),
    actions,
    getters,
    mutations,
  });

export default createStore;
