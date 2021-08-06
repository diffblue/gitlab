import actionsFactory from './actions';
import * as getters from './getters';
import mutationsFactory from './mutations';
import createState from './state';

export default ({ mapStateToPayload, mapDataToState, updateMethod = 'put' }) => ({
  state: createState(),
  actions: actionsFactory(mapStateToPayload, updateMethod),
  mutations: mutationsFactory(mapDataToState),
  getters,
});
