import Vue from 'vue';
import ReportNotConfiguredProject from 'ee/security_dashboard/components/project/report_not_configured_project.vue';
import ReportNotConfiguredGroup from 'ee/security_dashboard/components/group/report_not_configured_group.vue';
import ReportNotConfiguredInstance from 'ee/security_dashboard/components/instance/report_not_configured_instance.vue';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import groupVulnerabilityGradesQuery from 'ee/security_dashboard/graphql/queries/group_vulnerability_grades.query.graphql';
import groupVulnerabilityHistoryQuery from 'ee/security_dashboard/graphql/queries/group_vulnerability_history.query.graphql';
import instanceVulnerabilityGradesQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_grades.query.graphql';
import instanceVulnerabilityHistoryQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_history.query.graphql';
import SecurityDashboard from './components/shared/security_dashboard.vue';
import ProjectSecurityCharts from './components/project/project_security_dashboard.vue';
import UnavailableState from './components/shared/empty_states/unavailable_state.vue';
import apolloProvider from './graphql/provider';

export default (el, dashboardType) => {
  if (!el) {
    return null;
  }

  if (el.dataset.isUnavailable) {
    return new Vue({
      el,
      render(createElement) {
        return createElement(UnavailableState, {
          props: { svgPath: el.dataset.emptyStateSvgPath },
        });
      },
    });
  }

  const {
    emptyStateSvgPath,
    groupFullPath,
    projectFullPath,
    securityConfigurationPath,
    securityDashboardEmptySvgPath,
    instanceDashboardSettingsPath,
  } = el.dataset;

  const hasProjects = parseBoolean(el.dataset.hasProjects);
  const hasVulnerabilities = parseBoolean(el.dataset.hasVulnerabilities);
  const provide = {
    emptyStateSvgPath,
    groupFullPath,
    projectFullPath,
    securityConfigurationPath,
    securityDashboardEmptySvgPath,
    instanceDashboardSettingsPath,
  };

  let props;
  let component;

  if (dashboardType === DASHBOARD_TYPES.GROUP) {
    component = hasProjects ? SecurityDashboard : ReportNotConfiguredGroup;
    props = {
      historyQuery: groupVulnerabilityHistoryQuery,
      gradesQuery: groupVulnerabilityGradesQuery,
    };
  } else if (dashboardType === DASHBOARD_TYPES.INSTANCE) {
    component = hasProjects ? SecurityDashboard : ReportNotConfiguredInstance;
    props = {
      historyQuery: instanceVulnerabilityHistoryQuery,
      gradesQuery: instanceVulnerabilityGradesQuery,
    };
  } else if (dashboardType === DASHBOARD_TYPES.PROJECT) {
    component = hasVulnerabilities ? ProjectSecurityCharts : ReportNotConfiguredProject;
    props = { projectFullPath };
  }

  return new Vue({
    el,
    name: 'SecurityDashboardRoot',
    apolloProvider,
    provide,
    render(createElement) {
      return createElement(component, { props });
    },
  });
};
