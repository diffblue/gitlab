import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import { createCustomersDotClient } from 'ee/lib/customers_dot_graphql';
import App from './components/app.vue';
import defaultClient from './graphql';
import createStore from './store';

Vue.use(VueApollo);

const customersDotClient = createCustomersDotClient();

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
