import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  convertObjectPropsToCamelCase,
  convertArrayToCamelCase,
  parseBoolean,
} from '~/lib/utils/common_utils';
import DashboardsApp from './dashboards_app.vue';
import createRouter from './router';
import AnalyticsDashboardsBreadcrumbs from './components/analytics_dashboards_breadcrumbs.vue';

const buildAnalyticsDashboardPointer = (analyticsDashboardPointerJSON = '') => {
  return analyticsDashboardPointerJSON.length
    ? convertObjectPropsToCamelCase(JSON.parse(analyticsDashboardPointerJSON))
    : null;
};

// TODO: Review replacing this when a breadcrumbs ViewComponent has been created https://gitlab.com/gitlab-org/gitlab/-/issues/367326
const injectVueAppBreadcrumbs = (router) => {
  const breadcrumbEls = document.querySelectorAll('nav .js-breadcrumbs-list li');
  const breadcrumbEl = breadcrumbEls[breadcrumbEls.length - 1];
  const lastCrumb = breadcrumbEl.children[0];
  const crumbs = [lastCrumb];
  const nestedBreadcrumbEl = document.createElement('div');

  breadcrumbEl.replaceChild(nestedBreadcrumbEl, lastCrumb);

  return new Vue({
    el: nestedBreadcrumbEl,
    router,
    components: {
      AnalyticsDashboardsBreadcrumbs,
    },
    render(createElement) {
      return createElement('analytics-dashboards-breadcrumbs', {
        class: breadcrumbEl.className,
        props: {
          crumbs,
        },
      });
    },
  });
};

export default () => {
  const el = document.getElementById('js-analytics-dashboards-list-app');

  if (!el) {
    return false;
  }

  const {
    dashboardProject: analyticsDashboardPointerJSON = '',
    trackingKey,
    namespaceId,
    namespaceFullPath,
    isProject,
    collectorHost,
    chartEmptyStateIllustrationPath,
    dashboardEmptyStateIllustrationPath,
    routerBase,
    features,
  } = el.dataset;

  const analyticsDashboardPointer = buildAnalyticsDashboardPointer(analyticsDashboardPointerJSON);

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        cacheConfig: {
          typePolicies: {
            Project: {
              fields: {
                productAnalyticsDashboards: {
                  keyArgs: ['projectPath', 'slug'],
                },
              },
            },
            ProductAnalyticsDashboard: {
              keyFields: ['slug'],
            },
          },
        },
      },
    ),
  });

  // This is a mini state to help the breadcrumb have the correct name
  const breadcrumbState = Vue.observable({
    name: '',
    updateName(value) {
      this.name = value;
    },
  });

  const router = createRouter(routerBase, breadcrumbState);

  injectVueAppBreadcrumbs(router);

  return new Vue({
    el,
    name: 'AnalyticsDashboardsRoot',
    apolloProvider,
    router,
    provide: {
      breadcrumbState,
      customDashboardsProject: analyticsDashboardPointer,
      trackingKey,
      namespaceFullPath,
      namespaceId,
      isProject: parseBoolean(isProject),
      collectorHost,
      chartEmptyStateIllustrationPath,
      dashboardEmptyStateIllustrationPath,
      features: convertArrayToCamelCase(JSON.parse(features)),
    },
    render(h) {
      return h(DashboardsApp);
    },
  });
};
