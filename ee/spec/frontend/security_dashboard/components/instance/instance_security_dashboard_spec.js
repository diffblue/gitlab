import { shallowMount } from '@vue/test-utils';
import InstanceSecurityDashboard from 'ee/security_dashboard/components/instance/instance_security_dashboard.vue';
import ReportNotConfiguredInstance from 'ee/security_dashboard/components/instance/report_not_configured_instance.vue';
import VulnerabilitySeverities from 'ee/security_dashboard/components/shared/project_security_status_chart.vue';
import SecurityDashboardLayout from 'ee/security_dashboard/components/shared/security_dashboard_layout.vue';
import VulnerabilitiesOverTimeChart from 'ee/security_dashboard/components/shared/vulnerabilities_over_time_chart.vue';
import vulnerabilityGradesQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_grades.query.graphql';
import vulnerabilityHistoryQuery from 'ee/security_dashboard/graphql/queries/instance_vulnerability_history.query.graphql';

describe('Instance Security Dashboard component', () => {
  let wrapper;

  const findSecurityDashboardLayout = () => wrapper.findComponent(SecurityDashboardLayout);
  const findVulnerabilitiesOverTimeChart = () =>
    wrapper.findComponent(VulnerabilitiesOverTimeChart);
  const findVulnerabilitySeverities = () => wrapper.findComponent(VulnerabilitySeverities);
  const findReportNotConfigured = () => wrapper.findComponent(ReportNotConfiguredInstance);

  const createWrapper = ({ hasProjects } = {}) => {
    wrapper = shallowMount(InstanceSecurityDashboard, {
      provide: { hasProjects },
      stubs: { SecurityDashboardLayout },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the empty state', () => {
    createWrapper({ hasProjects: false });

    expect(findSecurityDashboardLayout().exists()).toBe(true);
    expect(findReportNotConfigured().exists()).toBe(true);
    expect(findVulnerabilitiesOverTimeChart().exists()).toBe(false);
    expect(findVulnerabilitySeverities().exists()).toBe(false);
  });

  it('renders the default page', async () => {
    createWrapper({ hasProjects: true });

    expect(findSecurityDashboardLayout().exists()).toBe(true);
    expect(findReportNotConfigured().exists()).toBe(false);
    expect(findVulnerabilitiesOverTimeChart().props('query')).toBe(vulnerabilityHistoryQuery);
    expect(findVulnerabilitySeverities().props('query')).toBe(vulnerabilityGradesQuery);
  });
});
