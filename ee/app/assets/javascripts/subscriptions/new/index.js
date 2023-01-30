import Vue from 'vue';
import VueApollo from 'vue-apollo';
import App from './components/app.vue';
import defaultClient from './graphql';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient,
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
