import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-storage-counter-app');
  const {
    namespacePath,
    helpPagePath,
    purchaseStorageUrl,
    isTemporaryStorageIncreaseVisible,
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(App, {
        props: {
          namespacePath,
          helpPagePath,
          purchaseStorageUrl,
          isTemporaryStorageIncreaseVisible,
        },
      });
    },
  });
};
