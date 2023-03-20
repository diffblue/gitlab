import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { s__ } from '~/locale';
import createDefaultClient from '~/lib/graphql';
import CiNamespaceCatalogApp from './ci_namespace_catalog_app.vue';
import { createRouter } from './router';
import { cacheConfig } from './graphql/settings';

export const initNamespaceCatalog = (selector = '#js-ci-namespace-catalog') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { dataset } = el;
  const { ciCatalogPath, projectFullPath } = dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, cacheConfig),
  });

  return new Vue({
    el,
    name: 'CiCatalogRoot',
    apolloProvider,
    router: createRouter(ciCatalogPath),
    provide: {
      projectFullPath,
      pageTitle: s__('CiCatalog|CI/CD catalog'),
      pageDescription: s__(
        'CiCatalog|Repositories of pipeline components available in this namespace.',
      ),
    },
    render(h) {
      return h(CiNamespaceCatalogApp);
    },
  });
};
