import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import createClient from '~/lib/graphql';
import App from './components/app.vue';
import defaultClient from './graphql';
import createStore from './store';

Vue.use(VueApollo);

const customersDotClient = createClient(
  {},
  {
    path: '/-/customers_dot/proxy/graphql',
    useGet: true,
  },
);

const apolloProvider = new VueApollo({
  defaultClient,
  clients: {
    [CUSTOMERSDOT_CLIENT]: customersDotClient,
  },
});

export default () => {
  const el = document.getElementById('js-new-subscription');
  const store = createStore(el.dataset);

  return new Vue({
    el,
    store,
    apolloProvider,
    components: {
      App,
    },
    render(createElement) {
      return createElement(App);
    },
  });
};
