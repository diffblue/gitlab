import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { projectHelpPaths as helpLinks } from './constants';
import NamespaceStorageApp from './components/namespace_storage_app.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-storage-counter-app');

  if (!el) {
    return false;
  }

  const {
    namespaceId,
    namespacePath,
    purchaseStorageUrl,
    buyAddonTargetAttr,
    defaultPerPage,
    storageLimitEnforced,
    canShowInlineAlert,
    additionalRepoStorageByNamespace,
    isPersonalNamespace,
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'NamespaceStorageApp',
    provide: {
      namespaceId,
      namespacePath,
      purchaseStorageUrl,
      buyAddonTargetAttr,
      helpLinks,
      defaultPerPage: Number(defaultPerPage),
    },
    render(createElement) {
      return createElement(NamespaceStorageApp, {
        props: {
          storageLimitEnforced: parseBoolean(storageLimitEnforced),
          canShowInlineAlert: parseBoolean(canShowInlineAlert),
          isAdditionalStorageFlagEnabled: parseBoolean(additionalRepoStorageByNamespace),
          isPersonalNamespace,
        },
      });
    },
  });
};
