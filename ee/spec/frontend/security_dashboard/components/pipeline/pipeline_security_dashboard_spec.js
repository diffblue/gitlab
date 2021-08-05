import { GlEmptyState } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline/pipeline_security_dashboard.vue';
import ScanErrorsAlert from 'ee/security_dashboard/components/pipeline/scan_errors_alert.vue';
import SecurityDashboard from 'ee/security_dashboard/components/pipeline/security_dashboard_vuex.vue';
import SecurityReportsSummary from 'ee/security_dashboard/components/pipeline/security_reports_summary.vue';
import VulnerabilityReport from 'ee/security_dashboard/components/shared/vulnerability_report.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const dashboardDocumentation = '/help/docs';
const emptyStateSvgPath = '/svgs/empty/svg';
const pipelineId = 1234;
const pipelineIid = 4321;
const projectId = 5678;
const sourceBranch = 'feature-branch-1';
const jobsPath = 'my-jobs-path';
const vulnerabilitiesEndpoint = '/vulnerabilities';
const loadingErrorIllustrations = {
  401: '/401.svg',
  403: '/403.svg',
};

describe('Pipeline Security Dashboard component', () => {
  let store;
  let wrapper;

  const findSecurityDashboard = () => wrapper.findComponent(SecurityDashboard);
  const findVulnerabilityReport = () => wrapper.findComponent(VulnerabilityReport);
  const findScanErrorsAlert = () => wrapper.findComponent(ScanErrorsAlert);

  const factory = ({ data, stubs, provide } = {}) => {
    store = new Vuex.Store({
      modules: {
        vulnerabilities: {
          namespaced: true,
          actions: {
            setSourceBranch() {},
          },
        },
        pipelineJobs: {
          namespaced: true,
          actions: {
            setPipelineJobsPath() {},
            setProjectId() {},
          },
        },
      },
    });
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(PipelineSecurityDashboard, {
      localVue,
      store,
      provide: {
        projectId,
        projectFullPath: 'my-path',
        emptyStateSvgPath,
        dashboardDocumentation,
        pipeline: {
          id: pipelineId,
          iid: pipelineIid,
          jobsPath,
          sourceBranch,
        },
        vulnerabilitiesEndpoint,
        loadingErrorIllustrations,
        ...provide,
      },
      stubs,
      data() {
        return {
          securityReportSummary: {},
          ...data,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches the expected actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        ['vulnerabilities/setSourceBranch', sourceBranch],
        ['pipelineJobs/setPipelineJobsPath', jobsPath],
        ['pipelineJobs/setProjectId', 5678],
      ]);
    });

    it('renders the security dashboard', () => {
      expect(findSecurityDashboard().props()).toMatchObject({
        pipelineId,
        vulnerabilitiesEndpoint,
      });
    });
  });

  describe(':pipeline_security_dashboard_graphql feature flag', () => {
    const factoryWithFeatureFlag = (value) =>
      factory({
        provide: {
          glFeatures: {
            pipelineSecurityDashboardGraphql: value,
          },
        },
      });

    it('does not show the security layout when the feature flag is on but the vulnerability report', () => {
      factoryWithFeatureFlag(true);
      expect(findSecurityDashboard().exists()).toBe(false);
      expect(findVulnerabilityReport().exists()).toBe(true);
    });

    it('shows the security layout when the feature flag is off', () => {
      factoryWithFeatureFlag(false);
      expect(findSecurityDashboard().exists()).toBe(true);
    });
  });

  describe('with a stubbed dashboard for slot testing', () => {
    beforeEach(() => {
      factory({
        stubs: {
          'security-dashboard': { template: '<div><slot name="empty-state"></slot></div>' },
        },
      });
    });

    it('renders empty state component with correct props', () => {
      const emptyState = wrapper.findComponent(GlEmptyState);

      expect(emptyState.props()).toMatchObject({
        svgPath: '/svgs/empty/svg',
        title: 'No vulnerabilities found for this pipeline',
        description: `While it's rare to have no vulnerabilities for your pipeline, it can happen. In any event, we ask that you double check your settings to make sure all security scanning jobs have passed successfully.`,
        primaryButtonLink: '/help/docs',
        primaryButtonText: 'Learn more about setting up your dashboard',
      });
    });
  });

  describe('scans error alert', () => {
    describe('with errors', () => {
      const reportSummary = {
        scanner_1: {
          // this scan contains errors
          scans: {
            nodes: [
              { errors: ['scanner 1 - error 1', 'scanner 1 - error 2'], name: 'foo' },
              { errors: ['scanner 1 - error 3', 'scanner 1 - error 4'], name: 'bar' },
            ],
          },
        },
        scanner_2: null,
        scanner_3: {
          // this scan contains errors
          scans: {
            nodes: [{ errors: ['scanner 3 - error 1', 'scanner 3 - error 2'], name: 'baz' }],
          },
        },
        scanner_4: {
          scans: {
            nodes: [{ errors: [], name: 'quz' }],
          },
        },
      };
      const scansWithErrors = [
        ...reportSummary.scanner_1.scans.nodes,
        ...reportSummary.scanner_3.scans.nodes,
      ];

      const securityReportSummary = {
        reports: reportSummary,
      };

      beforeEach(() => {
        factory({
          data: {
            securityReportSummary,
          },
        });
      });

      it('shows an alert with information about each scan with errors', () => {
        expect(findScanErrorsAlert().props('scans')).toEqual(scansWithErrors);
      });
    });

    describe('without errors', () => {
      const reportSummary = {
        dast: {
          scans: [
            {
              name: 'dast',
              errors: [],
            },
          ],
        },
      };

      const securityReportSummary = {
        reports: reportSummary,
      };

      beforeEach(() => {
        factory({
          data: {
            securityReportSummary,
          },
        });
      });

      it('does not show the alert', () => {
        expect(findScanErrorsAlert().exists()).toBe(false);
      });
    });
  });

  describe('security reports summary', () => {
    const reportSummary = {
      dast: {
        vulnerabilitiesCount: 123,
      },
    };

    const securityReportSummary = {
      reports: reportSummary,
    };

    it('shows the summary if it is non-empty', () => {
      factory({
        data: {
          securityReportSummary,
        },
      });
      expect(wrapper.findComponent(SecurityReportsSummary).exists()).toBe(true);
    });

    it('does not show the summary if it is empty', () => {
      factory({
        data: {
          securityReportSummary: null,
        },
      });
      expect(wrapper.findComponent(SecurityReportsSummary).exists()).toBe(false);
    });
  });
});
