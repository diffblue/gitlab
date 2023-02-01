import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { projectHelpPaths as helpLinks } from '~/usage_quotas/storage/constants';
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
    userNamespace,
    defaultPerPage,
    purchaseStorageUrl,
    buyAddonTargetAttr,
    storageLimitEnforced,
    canShowInlineAlert,
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
      userNamespace: parseBoolean(userNamespace),
      defaultPerPage: Number(defaultPerPage),
      purchaseStorageUrl,
      buyAddonTargetAttr,
      storageLimitEnforced: parseBoolean(storageLimitEnforced),
      canShowInlineAlert: parseBoolean(canShowInlineAlert),
      helpLinks,
    },
    render(createElement) {
      return createElement(NamespaceStorageApp);
    },
  });
};
