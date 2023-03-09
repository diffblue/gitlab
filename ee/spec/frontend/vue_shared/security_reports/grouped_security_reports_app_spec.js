import { GlButton, GlPopover, GlLink } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import GroupedSecurityReportsApp from 'ee/vue_shared/security_reports/grouped_security_reports_app.vue';
import appStore from 'ee/vue_shared/security_reports/store';
import { trackMrSecurityReportDetails } from 'ee/vue_shared/security_reports/store/constants';
import * as apiFuzzingTypes from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/mutation_types';
import * as sastTypes from 'ee/vue_shared/security_reports/store/modules/sast/mutation_types';
import * as secretDetectionTypes from 'ee/vue_shared/security_reports/store/modules/secret_detection/mutation_types';
import * as types from 'ee/vue_shared/security_reports/store/mutation_types';
import { trimText } from 'helpers/text_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { waitForMutation, mountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import GroupedIssuesList from '~/ci/reports/components/grouped_issues_list.vue';
import ReportSection from '~/ci/reports/components/report_section.vue';
import { STATUS_CLOSED, STATUS_MERGED, STATUS_OPEN } from '~/issues/constants';
import MergeRequestArtifactDownload from '~/vue_shared/security_reports/components/artifact_downloads/merge_request_artifact_download.vue';
import {
  sastDiffSuccessMock,
  dastDiffSuccessMock,
  containerScanningDiffSuccessMock,
  dependencyScanningDiffSuccessMock,
  secretDetectionDiffSuccessMock,
  coverageFuzzingDiffSuccessMock,
  apiFuzzingDiffSuccessMock,
  mockFindings,
} from './mock_data';

const CONTAINER_SCANNING_DIFF_ENDPOINT = 'container_scanning.json';
const DEPENDENCY_SCANNING_DIFF_ENDPOINT = 'dependency_scanning.json';
const DAST_DIFF_ENDPOINT = 'dast.json';
const SAST_DIFF_ENDPOINT = 'sast.json';
const PIPELINE_JOBS_ENDPOINT = 'jobs.json';
const SECRET_DETECTION_DIFF_ENDPOINT = 'secret_detection.json';
const API_FUZZING_DIFF_ENDPOINT = 'api_fuzzing.json';
const COVERAGE_FUZZING_DIFF_ENDPOINT = 'coverage_fuzzing.json';

describe('Grouped security reports app', () => {
  let wrapper;
  let mock;

  const findReportSection = () => wrapper.findComponent(ReportSection);
  const findReportSummary = () => wrapper.find('[data-testid="report-section-code-text"]');
  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findSpinner = () => wrapper.find('.gl-spinner');
  const findSecretDetectionReport = () => wrapper.find('[data-testid="secret-detection-report"]');
  const findFullReportButton = () => wrapper.find('.report-btn');
  const findDastJobLink = () => wrapper.find('[data-testid="dast-ci-job-link"]');

  const props = {
    headBlobPath: 'path',
    baseBlobPath: 'path',
    sastHelpPath: 'path',
    containerScanningHelpPath: 'path',
    dastHelpPath: 'path',
    dependencyScanningHelpPath: 'path',
    secretDetectionHelpPath: 'path',
    canReadVulnerabilityFeedbackPath: true,
    vulnerabilityFeedbackPath: 'vulnerability_feedback_path.json',
    coverageFuzzingHelpPath: 'path',
    apiFuzzingHelpPath: 'path',
    pipelineId: 123,
    projectId: 321,
    mrIid: 123,
    projectFullPath: 'path',
    targetProjectFullPath: 'path',
    apiFuzzingComparisonPath: API_FUZZING_DIFF_ENDPOINT,
    containerScanningComparisonPath: CONTAINER_SCANNING_DIFF_ENDPOINT,
    coverageFuzzingComparisonPath: COVERAGE_FUZZING_DIFF_ENDPOINT,
    dastComparisonPath: DAST_DIFF_ENDPOINT,
    dependencyScanningComparisonPath: DEPENDENCY_SCANNING_DIFF_ENDPOINT,
    sastComparisonPath: SAST_DIFF_ENDPOINT,
    secretDetectionComparisonPath: SECRET_DETECTION_DIFF_ENDPOINT,
  };

  const defaultDastSummary = {
    scannedResourcesCount: 211,
    scannedResources: { nodes: [] },
    scannedResourcesCsvPath: '',
  };

  const glModalDirective = jest.fn();

  const createWrapper = (propsData, options, provide) => {
    wrapper = mountExtended(GroupedSecurityReportsApp, {
      propsData,
      stubs: {
        VulnerabilityTraining: true,
      },
      mocks: {
        $apollo: {
          queries: {
            reportArtifacts: {
              loading: false,
            },
          },
        },
      },
      data() {
        return {
          dastSummary: defaultDastSummary,
          ...options?.data,
        };
      },
      directives: {
        glModal: {
          bind(el, { value }) {
            glModalDirective(value);
          },
        },
      },
      store: appStore(),
      provide: {
        ...provide,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('vulnerability_feedback_path.json').reply(HTTP_STATUS_OK, []);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('all reports', () => {
    const allReportProps = {
      ...props,
      enabledReports: {
        sast: true,
        dast: true,
        containerScanning: true,
        dependencyScanning: true,
        secretDetection: true,
        coverageFuzzing: true,
        apiFuzzing: true,
      },
    };

    describe('info button and popover', () => {
      beforeEach(() => {
        createWrapper(allReportProps);
      });

      it('shows the info button', () => {
        expect(wrapper.findByTestId('info-button').props()).toMatchObject({
          variant: 'link',
          icon: 'information-o',
        });
      });

      it('shows the info popover', () => {
        const popover = wrapper.findComponent(GlPopover);

        expect(popover.text()).toContain(GroupedSecurityReportsApp.i18n.infoPopover.title);
        expect(popover.text()).toContain(GroupedSecurityReportsApp.i18n.infoPopover.description);
        expect(popover.findComponent(GlLink).attributes('href')).toBe(
          GroupedSecurityReportsApp.infoPopoverHelpPagePath,
        );
      });
    });

    describe('with error', () => {
      beforeEach(() => {
        mock.onGet(CONTAINER_SCANNING_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock.onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock.onGet(DAST_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock.onGet(SECRET_DETECTION_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock.onGet(COVERAGE_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        mock.onGet(API_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        createWrapper(allReportProps);

        return Promise.all([
          waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_ERROR}`),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_CONTAINER_SCANNING_DIFF_ERROR),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_ERROR),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR),
          waitForMutation(
            wrapper.vm.$store,
            `secretDetection/${secretDetectionTypes.RECEIVE_DIFF_ERROR}`,
          ),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_COVERAGE_FUZZING_DIFF_ERROR),
          waitForMutation(wrapper.vm.$store, `apiFuzzing/${apiFuzzingTypes.RECEIVE_DIFF_ERROR}`),
        ]);
      });

      it('renders error state', () => {
        expect(findSpinner().exists()).toBe(false);
        expect(findReportSummary().text()).toEqual('Security scanning failed loading any results');

        expect(findCollapseButton().exists()).toBe(true);

        const wrapperText = wrapper.text();
        expect(wrapperText).toContain('SAST: Loading resulted in an error');

        expect(wrapperText).toContain('Dependency scanning: Loading resulted in an error');

        expect(wrapperText).toContain('Container scanning: Loading resulted in an error');

        expect(wrapperText).toContain('DAST: Loading resulted in an error');

        expect(wrapperText).toContain('Secret detection: Loading resulted in an error');
      });
    });

    describe('while loading', () => {
      it('renders loading summary text + spinner', () => {
        mock.onGet(PIPELINE_JOBS_ENDPOINT).reply(HTTP_STATUS_OK, {});
        mock.onGet(CONTAINER_SCANNING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {});
        mock.onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {});
        mock.onGet(DAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {});
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {});
        mock.onGet(SECRET_DETECTION_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {});
        mock.onGet(COVERAGE_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {});
        mock.onGet(API_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {});

        createWrapper(allReportProps);

        expect(findSpinner().exists()).toBe(true);
        expect(findReportSummary().text()).toEqual('Security scanning is loading');

        expect(findCollapseButton().exists()).toBe(true);

        const wrapperText = wrapper.text();
        expect(wrapperText).toContain('SAST is loading');
        expect(wrapperText).toContain('Dependency scanning is loading');
        expect(wrapperText).toContain('Container scanning is loading');
        expect(wrapperText).toContain('DAST is loading');
        expect(wrapperText).toContain('Coverage fuzzing is loading');
        expect(wrapperText).toContain('API fuzzing is loading');
      });
    });

    describe('with empty reports', () => {
      beforeEach(() => {
        const emptyResponse = { ...dastDiffSuccessMock, fixed: [], added: [] };
        mock.onGet(CONTAINER_SCANNING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, emptyResponse);
        mock.onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, emptyResponse);
        mock.onGet(DAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, emptyResponse);
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, emptyResponse);
        mock.onGet(SECRET_DETECTION_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, emptyResponse);
        mock.onGet(COVERAGE_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, emptyResponse);
        mock.onGet(API_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, emptyResponse);

        createWrapper(allReportProps);

        return Promise.all([
          waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS),
          waitForMutation(
            wrapper.vm.$store,
            `secretDetection/${secretDetectionTypes.RECEIVE_DIFF_SUCCESS}`,
          ),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_COVERAGE_FUZZING_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, `apiFuzzing/${apiFuzzingTypes.RECEIVE_DIFF_SUCCESS}`),
        ]);
      });

      it('renders reports', () => {
        // It's not loading
        expect(findSpinner().exists()).toBe(false);

        // Renders the summary text
        expect(findReportSummary().text()).toEqual(
          'Security scanning detected no new vulnerabilities.',
        );

        const wrapperText = wrapper.text();

        // Renders Sast result
        expect(wrapperText).toContain('SAST detected no new vulnerabilities.');

        // Renders DSS result
        expect(wrapper.text()).toContain('Dependency scanning detected no new vulnerabilities.');

        // Renders container scanning result
        expect(wrapperText).toContain('Container scanning detected no new vulnerabilities.');

        // Renders DAST result
        expect(wrapperText).toContain('DAST detected no new vulnerabilities.');

        // Renders Coverage Fuzzing result
        expect(wrapperText).toContain('Coverage fuzzing detected no new vulnerabilities.');

        // Renders API Fuzzing result
        expect(wrapperText).toContain('API fuzzing detected no new vulnerabilities.');
      });
    });

    describe('with successful responses', () => {
      let trackingSpy;
      const { category } = trackMrSecurityReportDetails;

      beforeEach(() => {
        mock
          .onGet(CONTAINER_SCANNING_DIFF_ENDPOINT)
          .reply(HTTP_STATUS_OK, containerScanningDiffSuccessMock);
        mock
          .onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT)
          .reply(HTTP_STATUS_OK, dependencyScanningDiffSuccessMock);
        mock.onGet(DAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, dastDiffSuccessMock);
        mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, sastDiffSuccessMock);
        mock
          .onGet(SECRET_DETECTION_DIFF_ENDPOINT)
          .reply(HTTP_STATUS_OK, secretDetectionDiffSuccessMock);
        mock
          .onGet(COVERAGE_FUZZING_DIFF_ENDPOINT)
          .reply(HTTP_STATUS_OK, coverageFuzzingDiffSuccessMock);
        mock.onGet(API_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, apiFuzzingDiffSuccessMock);

        createWrapper(allReportProps);
        trackingSpy = mockTracking(category, wrapper.element, jest.spyOn);

        return Promise.all([
          waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS),
          waitForMutation(
            wrapper.vm.$store,
            `secretDetection/${secretDetectionTypes.RECEIVE_DIFF_SUCCESS}`,
          ),
          waitForMutation(wrapper.vm.$store, types.RECEIVE_COVERAGE_FUZZING_DIFF_SUCCESS),
          waitForMutation(wrapper.vm.$store, `apiFuzzing/${apiFuzzingTypes.RECEIVE_DIFF_SUCCESS}`),
        ]);
      });

      afterEach(() => {
        unmockTracking();
      });

      const eventName = (toolName, eventType) =>
        `mr_widget_findings_counts_${toolName}_${eventType}`;

      it.each`
        toolName                 | report
        ${'coverage_fuzzing'}    | ${coverageFuzzingDiffSuccessMock}
        ${'sast'}                | ${sastDiffSuccessMock}
        ${'container_scanning'}  | ${containerScanningDiffSuccessMock}
        ${'dast'}                | ${dastDiffSuccessMock}
        ${'dependency_scanning'} | ${dependencyScanningDiffSuccessMock}
        ${'secret_detection'}    | ${secretDetectionDiffSuccessMock}
        ${'api_fuzzing'}         | ${apiFuzzingDiffSuccessMock}
      `('track reports for "$toolName', ({ toolName, report }) => {
        expect(trackingSpy).toHaveBeenCalledWith(category, eventName(toolName, 'fixed'), {
          value: report.fixed.length,
        });
        expect(trackingSpy).toHaveBeenCalledWith(category, eventName(toolName, 'added'), {
          value: report.added.length,
        });
      });

      it('renders reports', () => {
        // It's not loading
        expect(findSpinner().exists()).toBe(false);

        // Renders the summary text
        expect(trimText(findReportSummary().text())).toEqual(
          'Security scanning detected 12 potential vulnerabilities 7 Critical 5 High and 0 Others',
        );

        // Renders the expand button
        expect(findCollapseButton().exists()).toBe(true);

        const normalizedWrapperText = trimText(wrapper.text());

        // Renders Sast result
        expect(normalizedWrapperText).toContain(
          'SAST detected 1 potential vulnerability 1 Critical 0 High and 0 Others',
        );

        // Renders DSS result
        expect(normalizedWrapperText).toContain(
          'Dependency scanning detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );

        // Renders container scanning result
        expect(normalizedWrapperText).toContain(
          'Container scanning detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );

        // Renders DAST result
        expect(normalizedWrapperText).toContain(
          'DAST detected 1 potential vulnerability 1 Critical 0 High and 0 Others',
        );

        // Renders coverage fuzzing scanning result
        expect(normalizedWrapperText).toContain(
          'Coverage fuzzing detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );

        // Renders api fuzzing scanning result
        expect(normalizedWrapperText).toContain(
          'API fuzzing detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );
      });

      it('opens modal with more information', async () => {
        wrapper.find('[aria-label="Vulnerability Name"]').trigger('click');

        await nextTick();

        expect(document.querySelector('.modal-title').textContent.trim()).toEqual(
          mockFindings[0].name,
        );

        expect(document.querySelector('.modal-body').textContent).toContain(
          mockFindings[0].solution,
        );
      });

      it.each`
        reportType               | resolvedIssues                             | unresolvedIssues
        ${'sast'}                | ${sastDiffSuccessMock.fixed}               | ${sastDiffSuccessMock.added}
        ${'dependency-scanning'} | ${dependencyScanningDiffSuccessMock.fixed} | ${dependencyScanningDiffSuccessMock.added}
        ${'container-scanning'}  | ${containerScanningDiffSuccessMock.fixed}  | ${containerScanningDiffSuccessMock.added}
        ${'dast'}                | ${dastDiffSuccessMock.fixed}               | ${dastDiffSuccessMock.added}
        ${'secret-detection'}    | ${secretDetectionDiffSuccessMock.fixed}    | ${secretDetectionDiffSuccessMock.added}
        ${'coverage-fuzzing'}    | ${coverageFuzzingDiffSuccessMock.fixed}    | ${coverageFuzzingDiffSuccessMock.added}
        ${'api-fuzzing'}         | ${apiFuzzingDiffSuccessMock.fixed}         | ${apiFuzzingDiffSuccessMock.added}
      `(
        'renders a grouped-issues-list with the correct props for "$reportType" issues',
        ({ reportType, resolvedIssues, unresolvedIssues }) => {
          const issuesList = wrapper.find(`[data-testid="${reportType}-issues-list"]`);

          expect(issuesList.is(GroupedIssuesList)).toBe(true);

          expect(issuesList.props()).toMatchObject({
            resolvedIssues,
            unresolvedIssues,
            component: 'SecurityIssueBody',
          });
        },
      );
    });
  });

  describe('with the pipelinePath prop', () => {
    const pipelinePath = '/path/to/the/pipeline';

    beforeEach(() => {
      createWrapper({
        headBlobPath: 'path',
        pipelinePath,
        projectFullPath: 'path',
        targetProjectFullPath: 'path',
        mrIid: 123,
      });
    });

    it('should calculate the security tab path', () => {
      expect(findFullReportButton().attributes()).toMatchObject({
        target: '_blank',
        href: `${pipelinePath}/security`,
      });
    });

    it('should render view full report button', () => {
      const button = findFullReportButton();
      expect(button.text()).toBe(GroupedSecurityReportsApp.i18n.fullReport);
      expect(button.props()).toMatchObject({
        category: 'tertiary',
        variant: 'info',
        size: 'small',
      });
    });
  });

  describe('coverage fuzzing reports', () => {
    beforeEach(() => {
      createWrapper(
        {
          ...props,
          enabledReports: {
            coverageFuzzing: true,
          },
        },
        {},
      );
    });

    it('renders', () => {
      expect(wrapper.find('.js-coverage-fuzzing-widget').exists()).toBe(true);
    });
  });

  describe('api fuzzing reports', () => {
    beforeEach(() => {
      mock.onGet(API_FUZZING_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, apiFuzzingDiffSuccessMock);

      createWrapper({
        ...props,
        enabledReports: {
          apiFuzzing: true,
        },
      });

      return waitForMutation(
        wrapper.vm.$store,
        `apiFuzzing/${apiFuzzingTypes.RECEIVE_DIFF_SUCCESS}`,
      );
    });

    it('should set setApiFuzzingDiffEndpoint', () => {
      expect(wrapper.vm.apiFuzzing.paths.diffEndpoint).toEqual(API_FUZZING_DIFF_ENDPOINT);
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(trimText(wrapper.text())).toContain(
        'API fuzzing detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
      );
    });
  });

  describe('container scanning reports', () => {
    beforeEach(() => {
      mock
        .onGet(CONTAINER_SCANNING_DIFF_ENDPOINT)
        .reply(HTTP_STATUS_OK, containerScanningDiffSuccessMock);

      createWrapper({
        ...props,
        enabledReports: {
          containerScanning: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_CONTAINER_SCANNING_DIFF_SUCCESS);
    });

    it('should set setContainerScanningDiffEndpoint', () => {
      expect(wrapper.vm.containerScanning.paths.diffEndpoint).toEqual(
        CONTAINER_SCANNING_DIFF_ENDPOINT,
      );
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(trimText(wrapper.text())).toContain(
        'Container scanning detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
      );
    });
  });

  describe('dependency scanning reports', () => {
    beforeEach(() => {
      mock
        .onGet(DEPENDENCY_SCANNING_DIFF_ENDPOINT)
        .reply(HTTP_STATUS_OK, dependencyScanningDiffSuccessMock);

      createWrapper({
        ...props,
        enabledReports: {
          dependencyScanning: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS);
    });

    it('should set setDependencyScanningDiffEndpoint', () => {
      expect(wrapper.vm.dependencyScanning.paths.diffEndpoint).toEqual(
        DEPENDENCY_SCANNING_DIFF_ENDPOINT,
      );
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(trimText(wrapper.text())).toContain(
        'Dependency scanning detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
      );
    });
  });

  describe('dast reports', () => {
    beforeEach(() => {
      mock.onGet(DAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {
        ...dastDiffSuccessMock,
        base_report_out_of_date: true,
      });

      createWrapper({
        ...props,
        enabledReports: {
          dast: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS);
    });

    it('should set setDastDiffEndpoint', () => {
      expect(wrapper.vm.dast.paths.diffEndpoint).toEqual(DAST_DIFF_ENDPOINT);
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(trimText(wrapper.text())).toContain(
        'DAST detected 1 potential vulnerability 1 Critical 0 High and 0 Others',
      );
    });

    it('shows the scanned URLs count and opens a modal', async () => {
      const jobLink = findDastJobLink();

      expect(wrapper.text()).toContain('211 URLs scanned');
      expect(jobLink.exists()).toBe(true);
      expect(jobLink.text()).toBe('View details');

      jobLink.vm.$emit('click');

      await nextTick();

      expect(glModalDirective).toHaveBeenCalled();
    });

    it('does not show scanned resources info if there is 0 scanned URL', () => {
      mock.onGet(DAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {
        ...dastDiffSuccessMock,
        base_report_out_of_date: true,
      });

      // set scanned urls count to 0
      const summaryWithoutUrls = {
        ...defaultDastSummary,
        scannedResourcesCount: 0,
      };

      createWrapper(
        {
          ...props,
          enabledReports: {
            dast: true,
          },
        },
        {
          data: {
            dastSummary: summaryWithoutUrls,
          },
        },
      );

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS).then(() => {
        expect(wrapper.text()).not.toContain('0 URLs scanned');
        expect(findDastJobLink().exists()).toBe(false);
      });
    });

    it('show download option when scanned resources are not available', () => {
      mock.onGet(DAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {
        ...dastDiffSuccessMock,
        base_report_out_of_date: true,
      });

      const summaryWithoutScannedResources = {
        scannedResourcesCsvPath: 'http://test',
      };

      createWrapper(
        {
          ...props,
          enabledReports: {
            dast: true,
          },
        },
        {
          data: {
            dastSummary: summaryWithoutScannedResources,
          },
        },
      );

      return waitForMutation(wrapper.vm.$store, types.RECEIVE_DAST_DIFF_SUCCESS).then(() => {
        const findDownloadDropdown = wrapper.findComponent(MergeRequestArtifactDownload);

        expect(findDownloadDropdown.exists()).toBe(true);
      });
    });
  });

  describe('secret Detection reports', () => {
    const initSecretDetection = (isEnabled = true) => {
      mock
        .onGet(SECRET_DETECTION_DIFF_ENDPOINT)
        .reply(HTTP_STATUS_OK, secretDetectionDiffSuccessMock);

      createWrapper({
        ...props,
        enabledReports: {
          secretDetection: isEnabled,
        },
      });

      return waitForMutation(
        wrapper.vm.$store,
        `secretDetection/${secretDetectionTypes.RECEIVE_DIFF_SUCCESS}`,
      );
    };

    describe('enabled', () => {
      beforeEach(() => {
        return initSecretDetection();
      });

      it('should render the component', () => {
        expect(findSecretDetectionReport().exists()).toBe(true);
      });

      it('should set diffEndpoint', () => {
        expect(wrapper.vm.secretDetection.paths.diffEndpoint).toEqual(
          SECRET_DETECTION_DIFF_ENDPOINT,
        );
      });

      it('should display the correct numbers of vulnerabilities', () => {
        expect(trimText(wrapper.text())).toContain(
          'Secret detection detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others',
        );
      });
    });

    describe('disabled', () => {
      beforeEach(() => {
        initSecretDetection(false);
      });

      it('should not render the component', () => {
        expect(findSecretDetectionReport().exists()).toBe(false);
      });
    });
  });

  describe('sast reports', () => {
    beforeEach(() => {
      mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, { ...sastDiffSuccessMock });

      createWrapper({
        ...props,
        enabledReports: {
          sast: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`);
    });

    it('should set setSastDiffEndpoint', () => {
      expect(wrapper.vm.sast.paths.diffEndpoint).toEqual(SAST_DIFF_ENDPOINT);
    });

    it('should display the correct numbers of vulnerabilities', () => {
      expect(trimText(wrapper.text())).toContain(
        'SAST detected 1 potential vulnerability 1 Critical 0 High and 0 Others',
      );
    });
  });

  describe('Out of date report', () => {
    const createComponent = ({ baseReportOutOfDate = false, ...extraProp }) => {
      mock.onGet(SAST_DIFF_ENDPOINT).reply(HTTP_STATUS_OK, {
        ...sastDiffSuccessMock,
        base_report_out_of_date: baseReportOutOfDate,
      });

      createWrapper({
        ...props,
        ...extraProp,
        targetBranch: 'main',
        enabledReports: {
          sast: true,
        },
      });

      return waitForMutation(wrapper.vm.$store, `sast/${sastTypes.RECEIVE_DIFF_SUCCESS}`);
    };

    describe('with active MR and base report is out of date', () => {
      beforeEach(() => {
        return createComponent({ mrState: STATUS_OPEN, baseReportOutOfDate: true });
      });

      it('should display out of date message', () => {
        expect(wrapper.text()).toContain(
          'Security report is out of date. Run a new pipeline for the target branch (main)',
        );
      });
    });

    describe('with active MR and diverged commit', () => {
      beforeEach(() => {
        return createComponent({ mrState: STATUS_OPEN, divergedCommitsCount: 1 });
      });

      it('should display out of date message', () => {
        expect(wrapper.text()).toContain(
          'Security report is out of date. Please update your branch with the latest changes from the target branch (main)',
        );
      });
    });

    describe('with active MR, base report out of date and diverged commit', () => {
      beforeEach(() => {
        return createComponent({
          mrState: STATUS_OPEN,
          divergedCommitsCount: 1,
          baseReportOutOfDate: true,
        });
      });

      it('should display out of date message', () => {
        expect(wrapper.text()).toContain(
          'Security report is out of date. Please update your branch with the latest changes from the target branch (main)',
        );
      });
    });

    describe('with active MR', () => {
      beforeEach(() => {
        return createComponent({ mrState: STATUS_OPEN });
      });

      it('should not display out of date message', () => {
        expect(wrapper.text()).not.toContain('Security report is out of date.');
      });
    });

    describe('with closed MR', () => {
      beforeEach(() => {
        return createComponent({
          mrState: STATUS_CLOSED,
          divergedCommitsCount: 1,
          baseReportOutOfDate: true,
        });
      });

      it('should not display out of date message', () => {
        expect(wrapper.text()).not.toContain('Security report is out of date.');
      });
    });

    describe('with merged MR', () => {
      beforeEach(() => {
        return createComponent({
          mrState: STATUS_MERGED,
          divergedCommitsCount: 1,
          baseReportOutOfDate: true,
        });
      });

      it('should not display out of date message', () => {
        expect(wrapper.text()).not.toContain('Security report is out of date.');
      });
    });
  });

  describe('track report section expansion using Snowplow', () => {
    let trackingSpy;
    const { category, action } = trackMrSecurityReportDetails;

    beforeEach(() => {
      createWrapper(props);
      trackingSpy = mockTracking(category, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks an event when toggled', async () => {
      expect(trackingSpy).not.toHaveBeenCalled();
      findReportSection().vm.$emit('toggleEvent');

      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(category, action);
    });

    it('tracks an event only the first time it is toggled', async () => {
      const report = findReportSection();

      expect(trackingSpy).not.toHaveBeenCalled();
      report.vm.$emit('toggleEvent');

      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(category, action);
      expect(trackingSpy).toHaveBeenCalledTimes(1);
      report.vm.$emit('toggleEvent');

      await nextTick();

      expect(trackingSpy).toHaveBeenCalledTimes(1);
    });
  });
});
