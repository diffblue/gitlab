import Vue from 'vue';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupSecurityCharts from './components/group/group_security_dashboard.vue';
import InstanceSecurityCharts from './components/instance/instance_security_dashboard.vue';
import ProjectSecurityCharts from './components/project/project_security_dashboard.vue';
import UnavailableState from './components/shared/empty_states/unavailable_state.vue';
import apolloProvider from './graphql/provider';
import createRouter from './router';
import createStore from './store';

export default (el, dashboardType) => {
  if (!el) {
    return null;
  }

  if (el.dataset.isUnavailable) {
    return new Vue({
      el,
      render(createElement) {
        return createElement(UnavailableState, {
          props: {
            link: el.dataset.dashboardDocumentation,
            svgPath: el.dataset.emptyStateSvgPath,
          },
        });
      },
    });
  }

  const props = {};
  const provide = {
    dashboardDocumentation: el.dataset.dashboardDocumentation,
    emptyStateSvgPath: el.dataset.emptyStateSvgPath,
    groupFullPath: el.dataset.groupFullPath,
    projectFullPath: el.dataset.projectFullPath,
    securityConfigurationPath: el.dataset.securityConfigurationPath,
    surveyRequestSvgPath: el.dataset.surveyRequestSvgPath,
    securityDashboardHelpPath: el.dataset.securityDashboardHelpPath,
    sbomSurveySvgPath: el.dataset.sbomSurveySvgPath,
  };

  let component;

  if (dashboardType === DASHBOARD_TYPES.GROUP) {
    component = GroupSecurityCharts;
    props.groupFullPath = el.dataset.groupFullPath;
  } else if (dashboardType === DASHBOARD_TYPES.INSTANCE) {
    component = InstanceSecurityCharts;
    provide.instanceDashboardSettingsPath = el.dataset.instanceDashboardSettingsPath;
  } else if (dashboardType === DASHBOARD_TYPES.PROJECT) {
    component = ProjectSecurityCharts;
    props.projectFullPath = el.dataset.projectFullPath;
    props.hasVulnerabilities = parseBoolean(el.dataset.hasVulnerabilities);
  }

  const router = createRouter();
  const store = createStore({ dashboardType });

  return new Vue({
    el,
    store,
    router,
    apolloProvider,
    provide: () => provide,
    render(createElement) {
      return createElement(component, { props });
    },
  });
};
