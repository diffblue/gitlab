import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';
import IterationBreadcrumb from './components/iteration_breadcrumb.vue';
import IterationForm from './components/iteration_form_without_vue_router.vue';
import IterationReport from './components/iteration_report_without_vue_router.vue';
import Iterations from './components/iterations.vue';
import { Namespace } from './constants';
import createRouter from './router';

Vue.use(GlToast);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      batchMax: 1,
    },
  ),
});

export function initIterationsList(namespaceType) {
  const el = document.querySelector('.js-iterations-list');
  return new Vue({
    el,
    name: 'IterationsRoot',
    apolloProvider,
    render(createElement) {
      return createElement(Iterations, {
        props: {
          fullPath: el.dataset.fullPath,
          canAdmin: parseBoolean(el.dataset.canAdmin),
          namespaceType,
          newIterationPath: el.dataset.newIterationPath,
        },
      });
    },
  });
}

export function initIterationForm() {
  const el = document.querySelector('.js-iteration-new');

  return new Vue({
    el,
    name: 'IterationFormRoot',
    apolloProvider,
    render(createElement) {
      return createElement(IterationForm, {
        props: {
          groupPath: el.dataset.groupFullPath,
          previewMarkdownPath: el.dataset.previewMarkdownPath,
          iterationsListPath: el.dataset.iterationsListPath,
        },
      });
    },
  });
}

export function initIterationReport({ namespaceType, initiallyEditing } = {}) {
  const el = document.querySelector('.js-iteration');

  const {
    fullPath,
    hasScopedLabelsFeature,
    iterationId,
    labelsFetchPath,
    iterationsListPath,
    editIterationPath,
    previewMarkdownPath,
    svgPath,
  } = el.dataset;
  const canEdit = parseBoolean(el.dataset.canEdit);

  return new Vue({
    el,
    name: 'IterationReportRoot',
    apolloProvider,
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(IterationReport, {
        props: {
          hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
          iterationId,
          labelsFetchPath,
          canEdit,
          editIterationPath,
          namespaceType,
          previewMarkdownPath,
          svgPath,
          initiallyEditing,
          iterationsListPath,
        },
      });
    },
  });
}

function injectVueRouterIntoBreadcrumbs(router, groupPath) {
  const breadCrumbEls = document.querySelectorAll('nav .js-breadcrumbs-list li');
  const breadCrumbEl = breadCrumbEls[breadCrumbEls.length - 1];
  const crumbs = [breadCrumbEl.querySelector('h2')];
  const nestedBreadcrumbEl = document.createElement('div');
  breadCrumbEl.replaceChild(nestedBreadcrumbEl, crumbs[0]);
  return new Vue({
    el: nestedBreadcrumbEl,
    name: 'IterationBreadcrumbRoot',
    router,
    apolloProvider,
    components: {
      IterationBreadcrumb,
    },
    provide: {
      groupPath,
    },
    render(createElement) {
      // workaround pending https://gitlab.com/gitlab-org/gitlab/-/merge_requests/48115
      const parentEl = breadCrumbEl.parentElement.parentElement;
      if (parentEl) {
        parentEl.classList.remove('breadcrumbs-container');
        parentEl.classList.add('gl-display-flex');
        parentEl.classList.add('w-100');
      }
      return createElement('iteration-breadcrumb');
    },
  });
}

export function initCadenceApp({ namespaceType }) {
  const el = document.querySelector('.js-iteration-cadence-app');

  if (!el) {
    return null;
  }

  const {
    fullPath,
    groupPath,
    cadencesListPath,
    canCreateCadence,
    canEditCadence,
    canCreateIteration,
    canEditIteration,
    hasScopedLabelsFeature,
    labelsFetchPath,
    previewMarkdownPath,
    noIssuesSvgPath,
  } = el.dataset;
  const router = createRouter({
    base: cadencesListPath,
    permissions: {
      canCreateCadence: parseBoolean(canCreateCadence),
      canEditCadence: parseBoolean(canEditCadence),
      canCreateIteration: parseBoolean(canCreateIteration),
      canEditIteration: parseBoolean(canEditIteration),
    },
  });

  injectVueRouterIntoBreadcrumbs(router, groupPath);

  return new Vue({
    el,
    name: 'IterationsRoot',
    router,
    apolloProvider,
    provide: {
      fullPath,
      cadencesListPath,
      canCreateCadence: parseBoolean(canCreateCadence),
      canEditCadence: parseBoolean(canEditCadence),
      namespaceType,
      canCreateIteration: parseBoolean(canCreateIteration),
      canEditIteration: parseBoolean(canEditIteration),
      hasScopedLabelsFeature: parseBoolean(hasScopedLabelsFeature),
      labelsFetchPath,
      previewMarkdownPath,
      noIssuesSvgPath,
    },
    render(createElement) {
      return createElement(App);
    },
  });
}

export const initGroupCadenceApp = () => initCadenceApp({ namespaceType: Namespace.Group });
export const initProjectCadenceApp = () => initCadenceApp({ namespaceType: Namespace.Project });
