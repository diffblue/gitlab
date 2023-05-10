import { GlEmptyState, GlButton } from '@gitlab/ui';
import { mapValues, pick } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import pipelineSecurityReportSummaryQuery from 'ee/security_dashboard/graphql/queries/pipeline_security_report_summary.query.graphql';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline/pipeline_security_dashboard.vue';
import ReportStatusAlert from 'ee/security_dashboard/components/pipeline/report_status_alert.vue';
import ScanAlerts, {
  TYPE_ERRORS,
  TYPE_WARNINGS,
} from 'ee/security_dashboard/components/pipeline/scan_alerts.vue';
import SecurityDashboard from 'ee/security_dashboard/components/pipeline/security_dashboard_vuex.vue';
import SecurityReportsSummary from 'ee/security_dashboard/components/pipeline/security_reports_summary.vue';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';
import { HTTP_STATUS_FORBIDDEN, HTTP_STATUS_UNAUTHORIZED } from '~/lib/utils/http_status';
import {
  pipelineSecurityReportSummary,
  pipelineSecurityReportSummaryWithErrors,
  pipelineSecurityReportSummaryWithWarnings,
  purgedPipelineSecurityReportSummaryWithErrors,
  purgedPipelineSecurityReportSummaryWithWarnings,
  scansWithErrors,
  scansWithWarnings,
  pipelineSecurityReportSummaryEmpty,
} from './mock_data';

const projectId = 5678;
const emptyStateSvgPath = '/svgs/empty/svg';
const pipelineId = 1234;
const pipelineIid = 4321;
const vulnerabilitiesEndpoint = '/vulnerabilities';
const loadingErrorIllustrations = {
  [HTTP_STATUS_UNAUTHORIZED]: '/401.svg',
  [HTTP_STATUS_FORBIDDEN]: '/403.svg',
};

describe('Pipeline Security Dashboard component', () => {
  let store;
  let wrapper;

  const findSecurityDashboard = () => wrapper.findComponent(SecurityDashboard);
  const findVulnerabilityReport = () => wrapper.findByTestId('pipeline-vulnerability-report');
  const findScanAlerts = () => wrapper.findComponent(ScanAlerts);
  const findReportStatusAlert = () => wrapper.findComponent(ReportStatusAlert);

  const factory = ({ stubs, provide, apolloProvider } = {}) => {
    wrapper = shallowMountExtended(PipelineSecurityDashboard, {
      apolloProvider,
      store,
      provide: {
        projectId,
        projectFullPath: 'my-path',
        emptyStateSvgPath,
        pipeline: {
          id: pipelineId,
          iid: pipelineIid,
        },
        vulnerabilitiesEndpoint,
        loadingErrorIllustrations,
        ...provide,
      },
      stubs: { PipelineVulnerabilityReport: true, ...stubs },
    });
  };

  const factoryWithApollo = ({ requestHandlers }) => {
    Vue.use(VueApollo);

    factory({ apolloProvider: createMockApollo(requestHandlers) });
  };

  describe('on creation', () => {
    beforeEach(() => {
      factory();
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
        primaryButtonLink: DOC_PATH_SECURITY_CONFIGURATION,
        primaryButtonText: 'Learn more about setting up your dashboard',
      });
    });
  });

  describe('report status alert', () => {
    describe('with purged scans', () => {
      beforeEach(async () => {
        factoryWithApollo({
          requestHandlers: [
            [
              pipelineSecurityReportSummaryQuery,
              jest.fn().mockResolvedValueOnce(purgedPipelineSecurityReportSummaryWithErrors),
            ],
          ],
        });
        await waitForPromises();
      });

      it('shows the alert', () => {
        expect(findReportStatusAlert().exists()).toBe(true);
      });
    });

    describe('without purged scans', () => {
      beforeEach(async () => {
        factoryWithApollo({
          requestHandlers: [
            [
              pipelineSecurityReportSummaryQuery,
              jest.fn().mockResolvedValueOnce(pipelineSecurityReportSummary),
            ],
          ],
        });
        await waitForPromises();
      });

      it('does not show the alert', () => {
        expect(findReportStatusAlert().exists()).toBe(false);
      });
    });
  });

  describe('scans error alert', () => {
    describe('with errors', () => {
      describe('with purged scans', () => {
        beforeEach(async () => {
          factoryWithApollo({
            requestHandlers: [
              [
                pipelineSecurityReportSummaryQuery,
                jest.fn().mockResolvedValueOnce(purgedPipelineSecurityReportSummaryWithErrors),
              ],
            ],
          });
          await waitForPromises();
        });

        it('does not show the alert', () => {
          expect(findScanAlerts().exists()).toBe(false);
        });
      });

      describe('without purged scans', () => {
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

  describe('page description', () => {
    it('shows page description and help link', () => {
      factory();

      expect(wrapper.html()).toContain(PipelineSecurityDashboard.i18n.pageDescription);
      expect(wrapper.findComponent(GlButton).attributes()).toMatchObject({
        variant: 'link',
        icon: 'question-o',
        target: '_blank',
        href: PipelineSecurityDashboard.i18n.pageDescriptionHelpLink,
      });
    });
  });

  describe('scan warnings', () => {
    describe('with warnings', () => {
      describe('with purged scans', () => {
        beforeEach(async () => {
          factoryWithApollo({
            requestHandlers: [
              [
                pipelineSecurityReportSummaryQuery,
                jest.fn().mockResolvedValueOnce(purgedPipelineSecurityReportSummaryWithWarnings),
              ],
            ],
          });
          await waitForPromises();
        });

        it('does not show the alert', () => {
          expect(findScanAlerts().exists()).toBe(false);
        });
      });

      describe('without purged scans', () => {
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
    it('when response is empty, does not show report summary', async () => {
      factoryWithApollo({
        requestHandlers: [
          [
            pipelineSecurityReportSummaryQuery,
            jest.fn().mockResolvedValueOnce(pipelineSecurityReportSummaryEmpty),
          ],
        ],
      });

      await waitForPromises();

      expect(wrapper.findComponent(SecurityReportsSummary).exists()).toBe(false);
    });

    it('with non-empty response, shows report summary', async () => {
      factoryWithApollo({
        requestHandlers: [
          [
            pipelineSecurityReportSummaryQuery,
            jest.fn().mockResolvedValueOnce(pipelineSecurityReportSummary),
          ],
        ],
      });

      await waitForPromises();

      expect(wrapper.findComponent(SecurityReportsSummary).props()).toEqual({
        jobs: [],
        summary: mapValues(
          pipelineSecurityReportSummary.data.project.pipeline.securityReportSummary,
          (obj) =>
            pick(obj, 'vulnerabilitiesCount', 'scannedResourcesCsvPath', 'scans', '__typename'),
        ),
      });
    });
  });
});
