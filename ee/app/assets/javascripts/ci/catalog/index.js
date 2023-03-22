import Vue from 'vue';
import VueApollo from 'vue-apollo';

import { s__ } from '~/locale';
import createDefaultClient from '~/lib/graphql';
import CiNamespaceCatalogApp from './ci_namespace_catalog_app.vue';
import { createRouter } from './router';

export const initNamespaceCatalog = (selector = '#js-ci-namespace-catalog') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { dataset } = el;
  const { ciCatalogPath } = dataset;

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    router: createRouter(ciCatalogPath),
    provide: {
      pageTitle: s__('CiCatalog|CI/CD catalog'),
      pageDescription: s__(
        'CiCatalog|Repositories of reusable pipeline components available in this namespace.',
      ),
    },
    render(h) {
      return h(CiNamespaceCatalogApp);
    },
  });
};
