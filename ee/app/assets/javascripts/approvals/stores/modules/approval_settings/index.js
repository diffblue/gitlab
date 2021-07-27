import actionsFactory from './actions';
import mutationsFactory from './mutations';
import createState from './state';

export default ({ mapStateToPayload, mapDataToState }) => ({
  state: createState(),
  actions: actionsFactory(mapStateToPayload),
  mutations: mutationsFactory(mapDataToState),
});
