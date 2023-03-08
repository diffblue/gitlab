import VueRouter from 'vue-router';

import { joinPaths } from '~/lib/utils/url_utility';

import { ROUTE_FRAMEWORKS, ROUTE_VIOLATIONS } from './constants';
import ViolationsReport from './components/violations_report/report.vue';
import FrameworksReport from './components/frameworks_report/report.vue';

export function createRouter(basePath, props, featureFlags) {
  const { mergeCommitsCsvExportPath, groupPath } = props;

  const routes = [
    {
      path: '/violations',
      name: ROUTE_VIOLATIONS,
      component: ViolationsReport,
      props: {
        mergeCommitsCsvExportPath,
        groupPath,
      },
    },
    featureFlags.complianceFrameworksReport && {
      path: '/frameworks',
      name: ROUTE_FRAMEWORKS,
      component: FrameworksReport,
      props: {
        groupPath,
      },
    },
    { path: '*', redirect: { name: ROUTE_VIOLATIONS } },
  ].filter(Boolean);

  return new VueRouter({
    mode: 'history',
    base: joinPaths(gon.relative_url_root || '', basePath),
    routes,
  });
}
