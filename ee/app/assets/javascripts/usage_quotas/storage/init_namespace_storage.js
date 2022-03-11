import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { projectHelpLinks as helpLinks } from './constants';
import NamespaceStorageApp from './components/namespace_storage_app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-storage-counter-app');
  const {
    namespacePath,
    purchaseStorageUrl,
    buyAddonTargetAttr,
    isTemporaryStorageIncreaseVisible,
    defaultPerPage,
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      namespacePath,
      purchaseStorageUrl,
      buyAddonTargetAttr,
      isTemporaryStorageIncreaseVisible,
      helpLinks,
      defaultPerPage: Number(defaultPerPage),
    },
    render(createElement) {
      return createElement(NamespaceStorageApp);
    },
  });
};
