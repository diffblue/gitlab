import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import pipelineSecurityReportSummaryQuery from 'ee/security_dashboard/graphql/queries/pipeline_security_report_summary.query.graphql';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline/pipeline_security_dashboard.vue';
import ScanAlerts, {
  TYPE_ERRORS,
  TYPE_WARNINGS,
} from 'ee/security_dashboard/components/pipeline/scan_alerts.vue';
import SecurityDashboard from 'ee/security_dashboard/components/pipeline/security_dashboard_vuex.vue';
import SecurityReportsSummary from 'ee/security_dashboard/components/pipeline/security_reports_summary.vue';
import PipelineVulnerabilityReport from 'ee/security_dashboard/components/pipeline/pipeline_vulnerability_report.vue';
import {
  pipelineSecurityReportSummary,
  pipelineSecurityReportSummaryWithErrors,
  pipelineSecurityReportSummaryWithWarnings,
  scansWithErrors,
  scansWithWarnings,
  pipelineSecurityReportSummaryEmpty,
} from './mock_data';

Vue.use(Vuex);

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
  const findVulnerabilityReport = () => wrapper.findComponent(PipelineVulnerabilityReport);
  const findScanAlerts = () => wrapper.findComponent(ScanAlerts);

  const factory = ({ stubs, provide, apolloProvider } = {}) => {
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
      apolloProvider,
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
    });
  };

  const factoryWithApollo = ({ requestHandlers }) => {
    Vue.use(VueApollo);

    factory({ apolloProvider: createMockApollo(requestHandlers) });
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
      beforeEach(async () => {
        factoryWithApollo({
          requestHandlers: [
            [
              pipelineSecurityReportSummaryQuery,
              jest.fn().mockResolvedValueOnce(pipelineSecurityReportSummaryWithErrors),
            ],
          ],
        });
        await waitForPromises();
      });

      it('shows an alert with information about each scan with errors', () => {
        expect(findScanAlerts().props()).toMatchObject({
          scans: scansWithErrors,
          type: TYPE_ERRORS,
        });
      });
    });

    describe('without errors', () => {
      beforeEach(() => {
        factoryWithApollo({
          requestHandlers: [
            [
              pipelineSecurityReportSummaryQuery,
              jest.fn().mockResolvedValueOnce(pipelineSecurityReportSummary),
            ],
          ],
        });
      });

      it('does not show the alert', () => {
        expect(findScanAlerts().exists()).toBe(false);
      });
    });
  });

  describe('scan warnings', () => {
    describe('with warnings', () => {
      beforeEach(async () => {
        factoryWithApollo({
          requestHandlers: [
            [
              pipelineSecurityReportSummaryQuery,
              jest.fn().mockResolvedValueOnce(pipelineSecurityReportSummaryWithWarnings),
            ],
          ],
        });
        await waitForPromises();
      });

      it('shows an alert with information about each scan with warnings', () => {
        expect(findScanAlerts().props()).toMatchObject({
          scans: scansWithWarnings,
          type: TYPE_WARNINGS,
        });
      });
    });

    describe('without warnings', () => {
      beforeEach(() => {
        factoryWithApollo({
          requestHandlers: [
            [
              pipelineSecurityReportSummaryQuery,
              jest.fn().mockResolvedValueOnce(pipelineSecurityReportSummary),
            ],
          ],
        });
      });

      it('does not show the alert', () => {
        expect(findScanAlerts().exists()).toBe(false);
      });
    });
  });

  describe('security reports summary', () => {
    it.each`
      response                              | shouldShowReportSummary
      ${pipelineSecurityReportSummary}      | ${true}
      ${pipelineSecurityReportSummaryEmpty} | ${false}
    `(
      'shows the summary is "$shouldShowReportSummary"',
      async ({ response, shouldShowReportSummary }) => {
        factoryWithApollo({
          requestHandlers: [
            [pipelineSecurityReportSummaryQuery, jest.fn().mockResolvedValueOnce(response)],
          ],
        });

        await waitForPromises();

        expect(wrapper.findComponent(SecurityReportsSummary).exists()).toBe(
          shouldShowReportSummary,
        );
      },
    );
  });
});
