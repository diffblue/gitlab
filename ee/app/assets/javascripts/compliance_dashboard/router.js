import VueRouter from 'vue-router';

import { joinPaths } from '~/lib/utils/url_utility';

import { ROUTE_STANDARDS_ADHERENCE, ROUTE_FRAMEWORKS, ROUTE_VIOLATIONS } from './constants';
import ViolationsReport from './components/violations_report/report.vue';
import FrameworksReport from './components/frameworks_report/report.vue';
import StandardsReport from './components/standards_adherence_report/report.vue';

export function createRouter(basePath, props) {
  const {
    adherenceReportUiEnabled,
    mergeCommitsCsvExportPath,
    groupPath,
    rootAncestorPath,
  } = props;

  const defaultRoute = adherenceReportUiEnabled ? ROUTE_STANDARDS_ADHERENCE : ROUTE_VIOLATIONS;

  const routes = [
    {
      path: '/standards_adherence',
      name: ROUTE_STANDARDS_ADHERENCE,
      component: StandardsReport,
      props: {
        groupPath,
      },
    },
    {
      path: '/violations',
      name: ROUTE_VIOLATIONS,
      component: ViolationsReport,
      props: {
        mergeCommitsCsvExportPath,
        groupPath,
      },
    },
    {
      path: '/frameworks',
      name: ROUTE_FRAMEWORKS,
      component: FrameworksReport,
      props: {
        groupPath,
        rootAncestorPath,
      },
    },
    { path: '*', redirect: { name: defaultRoute } },
  ];

  return new VueRouter({
    mode: 'history',
    base: joinPaths(gon.relative_url_root || '', basePath),
    routes,
  });
}
