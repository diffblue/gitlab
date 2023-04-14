import { GlBadge } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import MRSecurityWidget from 'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import FindingModal from 'ee/vue_shared/security_reports/components/modal.vue';
import SummaryText from 'ee/vue_merge_request_widget/extensions/security_reports/summary_text.vue';
import SummaryHighlights from 'ee/vue_merge_request_widget/extensions/security_reports/summary_highlights.vue';
import findingQuery from 'ee/security_dashboard/graphql/queries/mr_widget_finding.graphql';
import dismissFindingMutation from 'ee/security_dashboard/graphql/mutations/dismiss_finding.mutation.graphql';
import revertFindingToDetectedMutation from 'ee/security_dashboard/graphql/mutations/revert_finding_to_detected.mutation.graphql';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import toast from '~/vue_shared/plugins/global_toast';
import download from '~/lib/utils/downloader';
import MrWidgetRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { findingMockData, findingQueryMockData } from './mock_data';

jest.mock('~/vue_shared/components/user_callout_dismisser.vue', () => ({ render: () => {} }));
jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('~/lib/utils/downloader');

Vue.use(VueApollo);

const DISMISSAL_RESPONSE = jest.fn().mockResolvedValue({
  data: {
    securityFindingDismiss: {
      errors: [],
      securityFinding: {
        vulnerability: {
          id: 1,
          stateTransitions: {
            nodes: {
              author: null,
              comment: 'comment',
              createdAt: '',
              toState: 'DISMISSED',
            },
          },
        },
      },
    },
  },
});

describe('MR Widget Security Reports', () => {
  let wrapper;
  let mockAxios;
  let emitSpy;

  const securityConfigurationPath = '/help/user/application_security/index.md';
  const sourceProjectFullPath = 'namespace/project';

  const sastHelp = '/help/user/application_security/sast/index';
  const dastHelp = '/help/user/application_security/dast/index';
  const coverageFuzzingHelp = '/help/user/application_security/coverage-fuzzing/index';
  const secretDetectionHelp = '/help/user/application_security/secret-detection/index';
  const apiFuzzingHelp = '/help/user/application_security/api-fuzzing/index';
  const dependencyScanningHelp = '/help/user/application_security/api-fuzzing/index';
  const containerScanningHelp = '/help/user/application_security/container-scanning/index';
  const createVulnerabilityFeedbackIssuePath = '/create/vulnerability/feedback/issue/path';
  const createVulnerabilityFeedbackDismissalPath = '/dismiss/finding/feedback/path';
  const createVulnerabilityFeedbackMergeRequestPath = '/create/merge/request/path';

  const reportEndpoints = {
    sastComparisonPathV2: '/my/sast/endpoint',
    dastComparisonPathV2: '/my/dast/endpoint',
    dependencyScanningComparisonPathV2: '/my/dependency-scanning/endpoint',
    coverageFuzzingComparisonPathV2: '/my/coverage-fuzzing/endpoint',
    apiFuzzingComparisonPathV2: '/my/api-fuzzing/endpoint',
    secretDetectionComparisonPathV2: '/my/secret-detection/endpoint',
    containerScanningComparisonPathV2: '/my/container-scanning/endpoint',
  };

  const createComponent = ({
    propsData,
    mountFn = shallowMountExtended,
    findingHandler = [findingQuery, findingQueryMockData()],
    additionalHandlers = [],
    deprecateVulnerabilitiesFeedback = true,
  } = {}) => {
    wrapper = mountFn(MRSecurityWidget, {
      apolloProvider: createMockApollo([findingHandler, ...additionalHandlers]),
      propsData: {
        ...propsData,
        mr: {
          pipeline: {
            path: '/path/to/pipeline',
          },
          enabledReports: {
            sast: true,
            dast: true,
            dependencyScanning: true,
            containerScanning: true,
            coverageFuzzing: true,
            apiFuzzing: true,
            secretDetection: true,
          },
          ...propsData?.mr,
          ...reportEndpoints,
          createVulnerabilityFeedbackMergeRequestPath,
          securityConfigurationPath,
          sourceProjectFullPath,
          sastHelp,
          dastHelp,
          containerScanningHelp,
          dependencyScanningHelp,
          coverageFuzzingHelp,
          secretDetectionHelp,
          apiFuzzingHelp,
        },
      },
      provide: {
        glFeatures: { deprecateVulnerabilitiesFeedback },
      },
      stubs: {
        MrWidgetRow,
      },
    });

    emitSpy = jest.spyOn(wrapper.vm.$root, '$emit');
  };

  const createComponentAndExpandWidget = async ({
    mockDataFn,
    mockDataProps,
    mrProps = {},
    additionalHandlers,
    deprecateVulnerabilitiesFeedback,
  }) => {
    mockDataFn(mockDataProps);
    createComponent({
      mountFn: mountExtended,
      additionalHandlers,
      propsData: {
        mr: mrProps,
      },
      deprecateVulnerabilitiesFeedback,
    });

    await waitForPromises();

    // Click on the toggle button to expand data
    wrapper.findByRole('button', { name: 'Show details' }).trigger('click');
    await nextTick();

    // Second next tick is for the dynamic scroller
    await nextTick();
  };

  const findWidget = () => wrapper.findComponent(Widget);
  const findWidgetRow = (reportType) => wrapper.findByTestId(`report-${reportType}`);
  const findSummaryText = () => wrapper.findComponent(SummaryText);
  const findSummaryHighlights = () => wrapper.findComponent(SummaryHighlights);
  const findDismissedBadge = () => wrapper.findComponent(GlBadge);
  const findModal = () => wrapper.findComponent(FindingModal);
  const findDynamicScroller = () => wrapper.findByTestId('dynamic-content-scroller');

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('with active pipeline', () => {
    beforeEach(() => {
      createComponent({ propsData: { mr: { isPipelineActive: true } } });
    });

    it('should not mount the widget component', () => {
      expect(findWidget().exists()).toBe(false);
    });
  });

  describe('with empty MR data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should mount the widget component', () => {
      expect(findWidget().props()).toMatchObject({
        statusIconName: 'success',
        widgetName: 'WidgetSecurityReports',
        errorText: 'Security reports failed loading results',
        loadingText: 'Loading',
        fetchCollapsedData: wrapper.vm.fetchCollapsedData,
        multiPolling: true,
      });
    });

    it('handles loading state', async () => {
      expect(findSummaryText().props()).toMatchObject({ isLoading: false });
      findWidget().vm.$emit('is-loading', true);
      await nextTick();
      expect(findSummaryText().props()).toMatchObject({ isLoading: true });
      expect(findSummaryHighlights().exists()).toBe(false);
    });

    it('does not display the summary highlights component', () => {
      expect(findSummaryHighlights().exists()).toBe(false);
    });

    it('should not be collapsible', () => {
      expect(findWidget().props('isCollapsible')).toBe(false);
    });
  });

  describe('with MR data', () => {
    const mockWithData = ({ findings } = {}) => {
      mockAxios.onGet(reportEndpoints.sastComparisonPathV2).replyOnce(
        HTTP_STATUS_OK,
        findings?.sast || {
          added: [
            {
              uuid: '1',
              severity: 'critical',
              name: 'Password leak',
              state: 'dismissed',
            },
            { uuid: '2', severity: 'high', name: 'XSS vulnerability' },
          ],
          fixed: [
            { uuid: '14abc', severity: 'high', name: 'SQL vulnerability' },
            { uuid: 'bc41e', severity: 'high', name: 'SQL vulnerability 2' },
          ],
        },
      );

      mockAxios.onGet(reportEndpoints.dastComparisonPathV2).replyOnce(
        HTTP_STATUS_OK,
        findings?.dast || {
          added: [
            { uuid: '5', severity: 'low', name: 'SQL Injection' },
            { uuid: '3', severity: 'unknown', name: 'Weak password' },
          ],
        },
      );

      [
        reportEndpoints.dependencyScanningComparisonPathV2,
        reportEndpoints.coverageFuzzingComparisonPathV2,
        reportEndpoints.apiFuzzingComparisonPathV2,
        reportEndpoints.secretDetectionComparisonPathV2,
        reportEndpoints.containerScanningComparisonPathV2,
      ].forEach((path) => {
        mockAxios.onGet(path).replyOnce(HTTP_STATUS_OK, {
          added: [],
        });
      });
    };

    const createComponentWithData = async () => {
      mockWithData();

      createComponent({
        mountFn: mountExtended,
      });

      await waitForPromises();
    };

    it('should make a call only for enabled reports', async () => {
      mockWithData();

      createComponent({
        mountFn: mountExtended,
        propsData: {
          mr: {
            enabledReports: {
              sast: true,
              dast: true,
            },
          },
        },
      });

      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(2);
    });

    it('should display the full report button', async () => {
      await createComponent();

      expect(findWidget().props('actionButtons')).toEqual([
        {
          href: '/path/to/pipeline/security',
          text: 'Full report',
          trackFullReportClicked: true,
        },
      ]);
    });

    it('should display the dismissed badge', async () => {
      await createComponentAndExpandWidget({ mockDataFn: mockWithData });
      expect(findDismissedBadge().text()).toBe('Dismissed');
    });

    it('should mount the widget component', async () => {
      await createComponentWithData();

      expect(findWidget().props()).toMatchObject({
        statusIconName: 'warning',
        widgetName: 'WidgetSecurityReports',
        errorText: 'Security reports failed loading results',
        loadingText: 'Loading',
        fetchCollapsedData: wrapper.vm.fetchCollapsedData,
        multiPolling: true,
      });
    });

    it('computes the total number of new potential vulnerabilities correctly', async () => {
      await createComponentWithData();

      expect(findSummaryText().props()).toMatchObject({ totalNewVulnerabilities: 4 });
      expect(findSummaryHighlights().props()).toMatchObject({
        highlights: { critical: 1, high: 1, other: 2 },
      });
    });

    it('tells the widget to be collapsible only if there is data', async () => {
      mockWithData();

      createComponent({
        mountFn: mountExtended,
      });

      expect(findWidget().props('isCollapsible')).toBe(false);
      await waitForPromises();
      expect(findWidget().props('isCollapsible')).toBe(true);
    });

    it('displays detailed data when expanded', async () => {
      await createComponentAndExpandWidget({ mockDataFn: mockWithData });

      expect(wrapper.findByText(/Weak password/).exists()).toBe(true);
      expect(wrapper.findByText(/Password leak/).exists()).toBe(true);
      expect(wrapper.findByTestId('SAST-report-header').text()).toBe(
        'SAST detected 2 new potential vulnerabilities',
      );
    });

    it('contains new and fixed findings in the dynamic scroller', async () => {
      await createComponentAndExpandWidget({ mockDataFn: mockWithData });

      expect(findDynamicScroller().props('items')).toEqual([
        // New findings
        {
          uuid: '1',
          severity: 'critical',
          name: 'Password leak',
          state: 'dismissed',
        },
        { uuid: '2', severity: 'high', name: 'XSS vulnerability' },
        // Fixed findings
        { uuid: '14abc', severity: 'high', name: 'SQL vulnerability' },
        { uuid: 'bc41e', severity: 'high', name: 'SQL vulnerability 2' },
      ]);

      expect(wrapper.findByTestId('new-findings-title').text()).toBe('New');
      expect(wrapper.findByTestId('fixed-findings-title').text()).toBe('Fixed');
    });

    it('contains only fixed findings in the dynamic scroller', async () => {
      await createComponentAndExpandWidget({
        mockDataFn: mockWithData,
        mockDataProps: {
          findings: {
            sast: {
              fixed: [
                { uuid: '14abc', severity: 'high', name: 'SQL vulnerability' },
                { uuid: 'bc41e', severity: 'high', name: 'SQL vulnerability 2' },
              ],
            },
            dast: {},
          },
        },
      });

      expect(findDynamicScroller().props('items')).toEqual([
        { uuid: '14abc', severity: 'high', name: 'SQL vulnerability' },
        { uuid: 'bc41e', severity: 'high', name: 'SQL vulnerability 2' },
      ]);

      expect(wrapper.findByTestId('new-findings-title').exists()).toBe(false);
      expect(wrapper.findByTestId('fixed-findings-title').text()).toBe('Fixed');
    });

    it('contains only added findings in the dynamic scroller', async () => {
      await createComponentAndExpandWidget({
        mockDataFn: mockWithData,
        mockDataProps: {
          findings: {
            sast: {},
          },
        },
      });

      expect(findDynamicScroller().props('items')).toEqual([
        { uuid: '5', severity: 'low', name: 'SQL Injection' },
        { uuid: '3', severity: 'unknown', name: 'Weak password' },
      ]);

      expect(wrapper.findByTestId('new-findings-title').text()).toBe('New');
      expect(wrapper.findByTestId('fixed-findings-title').exists()).toBe(false);
    });
  });

  describe('error states', () => {
    const mockWithData = () => {
      mockAxios.onGet(reportEndpoints.sastComparisonPathV2).replyOnce(HTTP_STATUS_BAD_REQUEST);

      mockAxios.onGet(reportEndpoints.dastComparisonPathV2).replyOnce(HTTP_STATUS_OK, {
        added: [
          { uuid: 5, severity: 'low', name: 'SQL Injection' },
          { uuid: 3, severity: 'unknown', name: 'Weak password' },
        ],
      });

      [
        reportEndpoints.dependencyScanningComparisonPathV2,
        reportEndpoints.coverageFuzzingComparisonPathV2,
        reportEndpoints.apiFuzzingComparisonPathV2,
        reportEndpoints.secretDetectionComparisonPathV2,
        reportEndpoints.containerScanningComparisonPathV2,
      ].forEach((path) => {
        mockAxios.onGet(path).replyOnce(HTTP_STATUS_OK, {
          added: [],
        });
      });
    };

    it('displays an error message for the individual level report', async () => {
      await createComponentAndExpandWidget({ mockDataFn: mockWithData });

      expect(wrapper.findByText('SAST: Loading resulted in an error').exists()).toBe(true);
    });
  });

  describe('help popovers', () => {
    const mockWithData = () => {
      Object.keys(reportEndpoints).forEach((key, i) => {
        mockAxios.onGet(reportEndpoints[key]).replyOnce(HTTP_STATUS_OK, {
          added: [{ uuid: i, severity: 'critical', name: 'Password leak' }],
        });
      });
    };

    it.each`
      reportType               | reportTitle                                      | helpPath
      ${'SAST'}                | ${'Static Application Security Testing (SAST)'}  | ${sastHelp}
      ${'DAST'}                | ${'Dynamic Application Security Testing (DAST)'} | ${dastHelp}
      ${'DEPENDENCY_SCANNING'} | ${'Dependency scanning'}                         | ${dependencyScanningHelp}
      ${'COVERAGE_FUZZING'}    | ${'Coverage fuzzing'}                            | ${coverageFuzzingHelp}
      ${'API_FUZZING'}         | ${'API fuzzing'}                                 | ${apiFuzzingHelp}
      ${'SECRET_DETECTION'}    | ${'Secret detection'}                            | ${secretDetectionHelp}
      ${'CONTAINER_SCANNING'}  | ${'Container scanning'}                          | ${containerScanningHelp}
    `(
      'shows the correct help popover for $reportType',
      async ({ reportType, reportTitle, helpPath }) => {
        await createComponentAndExpandWidget({ mockDataFn: mockWithData });

        expect(findWidgetRow(reportType).props('helpPopover')).toMatchObject({
          options: { title: reportTitle },
          content: { learnMorePath: helpPath },
        });
      },
    );
  });

  describe('modal', () => {
    const mockWithData = (props) => {
      Object.keys(reportEndpoints).forEach((key, i) => {
        mockAxios.onGet(reportEndpoints[key]).replyOnce(HTTP_STATUS_OK, {
          added: [
            {
              uuid: i.toString(),
              severity: 'critical',
              name: 'Password leak',
              found_by_pipeline: {
                iid: 1,
              },
              ...props,
            },
          ],
        });
      });
    };

    const createComponentExpandWidgetAndOpenModal = async ({
      mockDataProps = {},
      mrProps,
      additionalHandlers,
      deprecateVulnerabilitiesFeedback,
    } = {}) => {
      await createComponentAndExpandWidget({
        mockDataFn: mockWithData,
        mockDataProps,
        mrProps,
        additionalHandlers,
        deprecateVulnerabilitiesFeedback,
      });

      // Click on the vulnerability name
      wrapper.findAllByText('Password leak').at(0).trigger('click');
    };

    it('does not display the modal until the finding is clicked', async () => {
      await createComponentAndExpandWidget({ mockDataFn: mockWithData });

      expect(findModal().exists()).toBe(false);
    });

    it('clears modal data when the modal is closed', async () => {
      await createComponentExpandWidgetAndOpenModal();

      expect(findModal().props('modal')).not.toBe(null);

      findModal().vm.$emit('hidden');
      await nextTick();

      expect(findModal().exists()).toBe(false);
    });

    it('renders the modal when the finding is clicked', async () => {
      await createComponentExpandWidgetAndOpenModal();

      const modal = findModal();

      expect(modal.props('canCreateIssue')).toBe(false);
      expect(modal.props('isDismissingVulnerability')).toBe(false);
      expect(modal.props('isLoadingAdditionalInfo')).toBe(true);

      await waitForPromises();

      expect(modal.props('isLoadingAdditionalInfo')).toBe(false);

      const { mergeRequest, issueLinks, vulnerability } = findingMockData;
      const { issue } = issueLinks.nodes[0];

      expect(modal.props('modal')).toMatchObject({
        title: 'Password leak',
        error: null,
        isShowingDeleteButtons: false,
        vulnerability: {
          uuid: '0',
          severity: 'critical',
          name: 'Password leak',
          state_transitions: vulnerability.stateTransitions.nodes.map(
            convertObjectPropsToSnakeCase,
          ),
          merge_request_links: [
            {
              author: mergeRequest.author,
              merge_request_path: mergeRequest.webUrl,
              created_at: mergeRequest.createdAt,
              merge_request_iid: mergeRequest.iid,
            },
          ],
          issue_links: [
            {
              author: issue.author,
              created_at: issue.createdAt,
              issue_url: issue.webUrl,
              issue_iid: issue.iid,
              link_type: 'created',
            },
          ],
        },
      });
    });

    it('renders the modal when the finding is clicked - deprecateVulnerabilitiesFeedback feature flag disabled', async () => {
      await createComponentExpandWidgetAndOpenModal({ deprecateVulnerabilitiesFeedback: false });

      const modal = findModal();

      expect(modal.props('canCreateIssue')).toBe(false);
      expect(modal.props('isDismissingVulnerability')).toBe(false);
      expect(modal.props('isLoadingAdditionalInfo')).toBe(true);

      await waitForPromises();

      expect(modal.props('isLoadingAdditionalInfo')).toBe(false);

      const { dismissedBy, dismissedAt, stateComment, mergeRequest, issueLinks } = findingMockData;
      const { issue } = issueLinks.nodes[0];

      expect(modal.props('modal')).toMatchObject({
        title: 'Password leak',
        error: null,
        isShowingDeleteButtons: false,
        vulnerability: {
          uuid: '0',
          severity: 'critical',
          name: 'Password leak',
          dismissal_feedback: {
            author: dismissedBy,
            created_at: dismissedAt,
            comment_details: { comment: stateComment },
          },
          merge_request_feedback: {
            author: mergeRequest.author,
            merge_request_path: mergeRequest.webUrl,
            created_at: mergeRequest.createdAt,
            merge_request_iid: mergeRequest.iid,
          },
          issue_feedback: {
            author: issue.author,
            created_at: issue.createdAt,
            issue_url: issue.webUrl,
            issue_iid: issue.iid,
            link_type: 'created',
          },
        },
      });
    });

    it('downloads a patch when the downloadPatch event is emitted', async () => {
      await createComponentExpandWidgetAndOpenModal({
        mockDataProps: {
          remediations: [{ diff: 'some-diff' }],
        },
      });

      findModal().vm.$emit('downloadPatch');

      expect(download).toHaveBeenCalledWith({
        fileData: 'some-diff',
        fileName: 'remediation.patch',
      });
    });

    describe('merge request creation', () => {
      it('handles merge request creation - success', async () => {
        const mergeRequestPath = '/merge/request/1';

        mockAxios.onPost(createVulnerabilityFeedbackMergeRequestPath).replyOnce(HTTP_STATUS_OK, {
          merge_request_links: [{ merge_request_path: mergeRequestPath }],
        });

        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });

        const spy = jest.spyOn(urlUtils, 'visitUrl');

        expect(findModal().props('isCreatingMergeRequest')).toBe(false);

        findModal().vm.$emit('createMergeRequest');

        await nextTick();

        expect(findModal().props('isCreatingMergeRequest')).toBe(true);

        await waitForPromises();

        expect(spy).toHaveBeenCalledWith(mergeRequestPath);
      });

      it('handles merge request creation - success - deprecateVulnerabilitiesFeedback feature flag disabled', async () => {
        const mergeRequestPath = '/merge/request/1';

        mockAxios.onPost(createVulnerabilityFeedbackMergeRequestPath).replyOnce(HTTP_STATUS_OK, {
          merge_request_path: mergeRequestPath,
        });

        await createComponentExpandWidgetAndOpenModal({
          deprecateVulnerabilitiesFeedback: false,
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });

        const spy = jest.spyOn(urlUtils, 'visitUrl');

        expect(findModal().props('isCreatingMergeRequest')).toBe(false);

        findModal().vm.$emit('createMergeRequest');

        await nextTick();

        expect(findModal().props('isCreatingMergeRequest')).toBe(true);

        await waitForPromises();

        expect(spy).toHaveBeenCalledWith(mergeRequestPath);
      });

      it('handles merge request creation - error', async () => {
        mockAxios
          .onPost(createVulnerabilityFeedbackMergeRequestPath)
          .replyOnce(HTTP_STATUS_BAD_REQUEST);

        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });

        findModal().vm.$emit('createMergeRequest');

        await waitForPromises();

        expect(findModal().props('modal').error).toBe(
          'There was an error creating the merge request. Please try again.',
        );
      });
    });

    describe('issue creation', () => {
      it('can create issue when createVulnerabilityFeedbackIssuePath is provided', async () => {
        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackIssuePath,
          },
        });

        expect(findModal().props('canCreateIssue')).toBe(true);
      });

      it('can create issue when user can create a jira issue', async () => {
        await createComponentExpandWidgetAndOpenModal({
          mockDataProps: {
            create_jira_issue_url: 'create/jira/issue/url',
          },
        });

        expect(findModal().props('canCreateIssue')).toBe(true);
      });

      it('handles issue creation - success', async () => {
        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackIssuePath,
          },
        });

        mockAxios.onPost(createVulnerabilityFeedbackIssuePath).replyOnce(HTTP_STATUS_OK, {
          issue_links: [{ issue_url: '/my/issue/url', link_type: 'created' }],
        });

        const spy = jest.spyOn(urlUtils, 'visitUrl');

        findModal().vm.$emit('createNewIssue');

        await waitForPromises();

        expect(spy).toHaveBeenCalledWith('/my/issue/url');
      });

      it('handles issue creation - success - deprecateVulnerabilitiesFeedback feature flag disabled', async () => {
        await createComponentExpandWidgetAndOpenModal({
          deprecateVulnerabilitiesFeedback: false,
          mrProps: {
            createVulnerabilityFeedbackIssuePath,
          },
        });

        mockAxios.onPost(createVulnerabilityFeedbackIssuePath).replyOnce(HTTP_STATUS_OK, {
          issue_url: '/my/issue/url',
        });

        const spy = jest.spyOn(urlUtils, 'visitUrl');

        findModal().vm.$emit('createNewIssue');

        await waitForPromises();

        expect(spy).toHaveBeenCalledWith('/my/issue/url');
      });

      it('handles issue creation - error', async () => {
        mockAxios.onPost(createVulnerabilityFeedbackIssuePath).replyOnce(HTTP_STATUS_BAD_REQUEST);

        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackIssuePath,
          },
        });

        findModal().vm.$emit('createNewIssue');

        await waitForPromises();

        expect(findModal().props('modal').error).toBe(
          'There was an error creating the issue. Please try again.',
        );
      });
    });

    describe('dismissing finding', () => {
      it('can dismiss finding when createVulnerabilityFeedbackDismissalPath is provided', async () => {
        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });

        expect(findModal().props('canDismissVulnerability')).toBe(true);
      });

      it('handles dismissing finding - success', async () => {
        await createComponentExpandWidgetAndOpenModal({
          additionalHandlers: [[dismissFindingMutation, DISMISSAL_RESPONSE]],
        });

        expect(findDismissedBadge().exists()).toBe(false);

        findModal().vm.$emit('dismissVulnerability');

        await waitForPromises();

        expect(toast).toHaveBeenCalledWith("Dismissed 'Password leak'");
        expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');

        // There should be a finding with the dismissed badge now
        expect(findDismissedBadge().text()).toBe('Dismissed');
      });

      it('handles dismissing finding - error', async () => {
        await createComponentExpandWidgetAndOpenModal({
          additionalHandlers: [[dismissFindingMutation, jest.fn().mockRejectedValue()]],
        });

        findModal().vm.$emit('dismissVulnerability');

        await waitForPromises();

        expect(findModal().props('modal').error).toBe(
          'There was an error dismissing the vulnerability. Please try again.',
        );

        expect(findDismissedBadge().exists()).toBe(false);
      });
    });

    describe.each([true, false])(
      'dismissal comment - deprecateVulnerabilities feature flag %s',
      (deprecateVulnerabilitiesFeedback) => {
        let mockDataProps;

        beforeEach(() => {
          mockDataProps = {
            state: 'dismissed',
            state_transitions: [
              {
                author: {},
                to_state: 'DISMISSED',
              },
            ],
            dismissal_feedback: {
              author: {},
              project_id: 20,
              id: 15,
            },
          };
        });

        it.each`
          event                                  | booleanValue
          ${'openDismissalCommentBox'}           | ${true}
          ${'closeDismissalCommentBox'}          | ${false}
          ${'editVulnerabilityDismissalComment'} | ${true}
        `('handles opening dismissal comment for event $event', async ({ event, booleanValue }) => {
          await createComponentExpandWidgetAndOpenModal({
            mockDataProps,
            deprecateVulnerabilitiesFeedback,
          });

          expect(findModal().props('modal').isCommentingOnDismissal).toBeUndefined();

          findModal().vm.$emit(event);

          await waitForPromises();

          expect(findModal().props('modal').isCommentingOnDismissal).toBe(booleanValue);
        });

        it('adds the dismissal comment - success', async () => {
          await createComponentExpandWidgetAndOpenModal({
            mockDataProps,
            additionalHandlers: [[dismissFindingMutation, DISMISSAL_RESPONSE]],
          });

          findModal().vm.$emit('addDismissalComment', 'Edited comment');

          await waitForPromises();

          expect(toast).toHaveBeenCalledWith("Comment added to 'Password leak'");
          expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');
        });

        it('edits the dismissal comment - success', async () => {
          await createComponentExpandWidgetAndOpenModal({
            mockDataProps,
            deprecateVulnerabilitiesFeedback,
            additionalHandlers: [[dismissFindingMutation, DISMISSAL_RESPONSE]],
          });

          await waitForPromises();

          findModal().vm.$emit('addDismissalComment', 'Edited comment');

          await waitForPromises();

          expect(toast).toHaveBeenCalledWith("Comment edited on 'Password leak'");
          expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');
        });

        it('adds the dismissal comment - error', async () => {
          await createComponentExpandWidgetAndOpenModal({
            mockDataProps,
            deprecateVulnerabilitiesFeedback,
            additionalHandlers: [[dismissFindingMutation, jest.fn().mockRejectedValue()]],
          });

          findModal().vm.$emit('addDismissalComment', 'Edited comment');

          await waitForPromises();

          expect(toast).not.toHaveBeenCalled();
          expect(findModal().props('modal').error).toBe('There was an error adding the comment.');
        });

        it('deletes the dismissal comment - success', async () => {
          mockDataProps.dismissal_feedback.comment_details = {
            comment: 'Existing comment',
            comment_author: { id: 15 },
          };

          await createComponentExpandWidgetAndOpenModal({
            mockDataProps,
            deprecateVulnerabilitiesFeedback,
            additionalHandlers: [[dismissFindingMutation, DISMISSAL_RESPONSE]],
          });

          expect(findModal().props('modal').isShowingDeleteButtons).toBe(false);

          // This displays the `Delete` button
          findModal().vm.$emit('showDismissalDeleteButtons');
          await nextTick();

          expect(findModal().props('modal').isShowingDeleteButtons).toBe(true);

          // This triggers the actual delete call
          findModal().vm.$emit('deleteDismissalComment');
          await nextTick();

          await waitForPromises();

          expect(toast).toHaveBeenCalledWith("Comment deleted on 'Password leak'");
          expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');
        });

        it('deletes the dismissal comment - error', async () => {
          mockDataProps.dismissal_feedback.comment_details = {
            comment: 'Existing comment',
            comment_author: { id: 15 },
          };

          await createComponentExpandWidgetAndOpenModal({
            mockDataProps,
            deprecateVulnerabilitiesFeedback,
            additionalHandlers: [[dismissFindingMutation, jest.fn().mockRejectedValue()]],
          });

          expect(findModal().props('modal').isShowingDeleteButtons).toBe(false);

          // This displays the `Delete` button
          findModal().vm.$emit('showDismissalDeleteButtons');
          await nextTick();

          expect(findModal().props('modal').isShowingDeleteButtons).toBe(true);

          // This triggers the actual delete call
          findModal().vm.$emit('deleteDismissalComment');
          await nextTick();

          await waitForPromises();

          expect(toast).not.toHaveBeenCalled();
          expect(findModal().props('modal').error).toBe('There was an error deleting the comment.');
        });
      },
    );

    describe('undo dismissing finding', () => {
      let mockDataProps;

      beforeEach(() => {
        mockDataProps = {
          state: 'dismissed',
          dismissal_feedback: {
            author: {},
          },
        };
      });

      it('handles undoing dismissing a finding - success', async () => {
        await createComponentExpandWidgetAndOpenModal({
          mockDataProps,
          additionalHandlers: [
            [
              revertFindingToDetectedMutation,
              jest.fn().mockResolvedValue({
                data: {
                  securityFindingRevertToDetected: {
                    errors: [],
                    securityFinding: {
                      vulnerability: {
                        id: 1,
                        stateTransitions: {
                          nodes: {
                            author: null,
                            comment: 'comment',
                            createdAt: '',
                            toState: 'DETECTED',
                          },
                        },
                      },
                    },
                  },
                },
              }),
            ],
          ],
        });

        findModal().vm.$emit('revertDismissVulnerability');

        await waitForPromises();

        expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');

        // The dismissal_feedback object should be set back to `null`.
        expect(findModal().props('modal').vulnerability.dismissal_feedback).toBe(null);
      });

      it('handles undoing dismissing a finding - error', async () => {
        await createComponentExpandWidgetAndOpenModal({
          mockDataProps,
          additionalHandlers: [[revertFindingToDetectedMutation, jest.fn().mockRejectedValue({})]],
        });

        findModal().vm.$emit('revertDismissVulnerability');

        await waitForPromises();

        expect(findModal().props('modal').error).toBe(
          'There was an error reverting the dismissal. Please try again.',
        );
      });
    });
  });
});
