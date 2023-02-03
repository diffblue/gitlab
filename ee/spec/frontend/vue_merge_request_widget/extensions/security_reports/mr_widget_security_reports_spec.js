import { GlBadge } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import MRSecurityWidget from 'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue';
import FindingModal from 'ee/vue_shared/security_reports/components/modal.vue';
import SummaryText from 'ee/vue_merge_request_widget/extensions/security_reports/summary_text.vue';
import SummaryHighlights from 'ee/vue_merge_request_widget/extensions/security_reports/summary_highlights.vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import toast from '~/vue_shared/plugins/global_toast';
import MrWidgetRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/vue_shared/components/user_callout_dismisser.vue', () => ({ render: () => {} }));
jest.mock('~/vue_shared/plugins/global_toast');

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

  const reportEndpoints = {
    sastComparisonPath: '/my/sast/endpoint',
    dastComparisonPath: '/my/dast/endpoint',
    dependencyScanningComparisonPath: '/my/dependency-scanning/endpoint',
    coverageFuzzingComparisonPath: '/my/coverage-fuzzing/endpoint',
    apiFuzzingComparisonPath: '/my/api-fuzzing/endpoint',
    secretDetectionComparisonPath: '/my/secret-detection/endpoint',
    containerScanningComparisonPath: '/my/container-scanning/endpoint',
  };

  const createComponent = ({ propsData, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(MRSecurityWidget, {
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
      stubs: {
        MrWidgetRow,
      },
    });

    emitSpy = jest.spyOn(wrapper.vm.$root, '$emit');
  };

  const createComponentAndExpandWidget = async ({ mockDataFn, mockDataProps, mrProps = {} }) => {
    mockDataFn(mockDataProps);
    createComponent({
      mountFn: mountExtended,
      propsData: {
        mr: mrProps,
      },
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
    const mockWithData = () => {
      mockAxios.onGet(reportEndpoints.sastComparisonPath).replyOnce(HTTP_STATUS_OK, {
        added: [
          {
            uuid: 1,
            severity: 'critical',
            name: 'Password leak',
            state: 'dismissed',
          },
          { uuid: 2, severity: 'high', name: 'XSS vulnerability' },
        ],
      });

      mockAxios.onGet(reportEndpoints.dastComparisonPath).replyOnce(HTTP_STATUS_OK, {
        added: [
          { uuid: 5, severity: 'low', name: 'SQL Injection' },
          { uuid: 3, severity: 'unknown', name: 'Weak password' },
        ],
      });

      [
        reportEndpoints.dependencyScanningComparisonPath,
        reportEndpoints.coverageFuzzingComparisonPath,
        reportEndpoints.apiFuzzingComparisonPath,
        reportEndpoints.secretDetectionComparisonPath,
        reportEndpoints.containerScanningComparisonPath,
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
          fullReport: true,
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

    it('passes correct items to the dynamic scroller', async () => {
      await createComponentAndExpandWidget({ mockDataFn: mockWithData });

      expect(findDynamicScroller().props('items')).toEqual([
        {
          uuid: 1,
          severity: 'critical',
          name: 'Password leak',
          state: 'dismissed',
        },
        { uuid: 2, severity: 'high', name: 'XSS vulnerability' },
      ]);
    });
  });

  describe('error states', () => {
    const mockWithData = () => {
      mockAxios.onGet(reportEndpoints.sastComparisonPath).replyOnce(HTTP_STATUS_BAD_REQUEST);

      mockAxios.onGet(reportEndpoints.dastComparisonPath).replyOnce(HTTP_STATUS_OK, {
        added: [
          { uuid: 5, severity: 'low', name: 'SQL Injection' },
          { uuid: 3, severity: 'unknown', name: 'Weak password' },
        ],
      });

      [
        reportEndpoints.dependencyScanningComparisonPath,
        reportEndpoints.coverageFuzzingComparisonPath,
        reportEndpoints.apiFuzzingComparisonPath,
        reportEndpoints.secretDetectionComparisonPath,
        reportEndpoints.containerScanningComparisonPath,
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
          added: [{ uuid: i, severity: 'critical', name: 'Password leak', ...props }],
        });
      });
    };

    const createComponentExpandWidgetAndOpenModal = async ({
      mockDataProps = {},
      mrProps,
    } = {}) => {
      await createComponentAndExpandWidget({
        mockDataFn: mockWithData,
        mockDataProps,
        mrProps,
      });

      // Click on the vulnerability name
      wrapper.findAllByText('Password leak').at(0).trigger('click');
      await nextTick();
    };

    it('does not display the modal until the finding is clicked', async () => {
      await createComponentAndExpandWidget({ mockDataFn: mockWithData });

      expect(findModal().exists()).toBe(false);
    });

    it('renders the modal when the finding is clicked', async () => {
      await createComponentExpandWidgetAndOpenModal();

      const modal = findModal();

      expect(modal.props('canCreateIssue')).toBe(false);
      expect(modal.props('isDismissingVulnerability')).toBe(false);
      expect(modal.props('modal')).toEqual({
        title: 'Password leak',
        error: null,
        isShowingDeleteButtons: false,
        vulnerability: {
          uuid: 0,
          severity: 'critical',
          name: 'Password leak',
          isDismissed: false,
        },
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
        mockAxios.onPost(createVulnerabilityFeedbackDismissalPath).replyOnce(HTTP_STATUS_OK);

        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });

        findModal().vm.$emit('dismissVulnerability');

        await waitForPromises();

        expect(toast).toHaveBeenCalledWith("Dismissed 'Password leak'");
        expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');
      });

      it('handles issue creation - error', async () => {
        mockAxios
          .onPost(createVulnerabilityFeedbackDismissalPath)
          .replyOnce(HTTP_STATUS_BAD_REQUEST);

        await createComponentExpandWidgetAndOpenModal({
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });

        findModal().vm.$emit('dismissVulnerability');

        await waitForPromises();

        expect(findModal().props('modal').error).toBe(
          'There was an error dismissing the vulnerability. Please try again.',
        );
      });
    });

    describe('dismissal comment', () => {
      let dismissalFeedback;

      beforeEach(async () => {
        dismissalFeedback = {
          author: {},
          project_id: 20,
          id: 15,
        };

        await createComponentExpandWidgetAndOpenModal({
          mockDataProps: {
            state: 'dismissed',
            dismissal_feedback: dismissalFeedback,
          },
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });
      });

      it.each`
        event                                  | booleanValue
        ${'openDismissalCommentBox'}           | ${true}
        ${'closeDismissalCommentBox'}          | ${false}
        ${'editVulnerabilityDismissalComment'} | ${true}
      `('handles opening dismissal comment for event $event', async ({ event, booleanValue }) => {
        mockAxios.onPost(createVulnerabilityFeedbackDismissalPath).replyOnce(HTTP_STATUS_OK);

        expect(findModal().props('modal').isCommentingOnDismissal).toBeUndefined();

        findModal().vm.$emit(event);

        await waitForPromises();

        expect(findModal().props('modal').isCommentingOnDismissal).toBe(booleanValue);
      });

      it('adds the dismissal comment - success', async () => {
        mockAxios
          .onPatch(`${createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`)
          .replyOnce(HTTP_STATUS_OK, dismissalFeedback);

        findModal().vm.$emit('addDismissalComment', 'Edited comment');

        await waitForPromises();

        expect(toast).toHaveBeenCalledWith("Comment added to 'Password leak'");
        expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');
      });

      it('edits the dismissal comment - success', async () => {
        mockAxios
          .onPatch(`${createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`)
          .reply(HTTP_STATUS_OK, {
            ...dismissalFeedback,
            comment_details: {
              comment: 'Added comment',
              comment_author: { id: 15 },
              comment_timestamp: '2023-01-24T12:46:03.896Z',
            },
          });

        // first add a comment
        findModal().vm.$emit('addDismissalComment', 'Added comment');
        await waitForPromises();

        // then edit
        findModal().vm.$emit('addDismissalComment', 'Edited comment');
        await waitForPromises();

        expect(toast).toHaveBeenCalledWith("Comment edited on 'Password leak'");
        expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');
      });

      it('adds the dismissal comment - error', async () => {
        mockAxios
          .onPatch(`${createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`)
          .replyOnce(HTTP_STATUS_BAD_REQUEST);

        findModal().vm.$emit('addDismissalComment', 'Edited comment');

        await waitForPromises();

        expect(toast).not.toHaveBeenCalled();
        expect(findModal().props('modal').error).toBe('There was an error adding the comment.');
      });

      it('deletes the dismissal comment - success', async () => {
        dismissalFeedback.comment_details = {
          comment: 'Test',
          comment_author: { id: 15 },
          comment_timestamp: '2023-01-24T12:46:03.896Z',
        };

        mockWithData({
          state: 'dismissed',
          dismissal_feedback: dismissalFeedback,
        });

        mockAxios
          .onPatch(`${createVulnerabilityFeedbackDismissalPath}/15`)
          .replyOnce(HTTP_STATUS_OK, dismissalFeedback);

        createComponent({
          mountFn: mountExtended,
          propsData: {
            mr: {
              createVulnerabilityFeedbackDismissalPath,
            },
          },
        });

        await waitForPromises();

        // Click on the toggle button to expand data
        wrapper.findByRole('button', { name: 'Show details' }).trigger('click');
        await nextTick();

        // Second one is for the dynamic scroller
        await nextTick();

        // Click on the vulnerability name
        wrapper.findAllByText('Password leak').at(0).trigger('click');
        await nextTick();

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
        dismissalFeedback.comment_details = {
          comment: 'Test',
          comment_author: { id: 15 },
          comment_timestamp: '2023-01-24T12:46:03.896Z',
        };

        mockWithData({
          state: 'dismissed',
          dismissal_feedback: dismissalFeedback,
        });

        mockAxios
          .onPatch(`${createVulnerabilityFeedbackDismissalPath}/15`)
          .replyOnce(HTTP_STATUS_BAD_REQUEST);

        createComponent({
          mountFn: mountExtended,
          propsData: {
            mr: {
              createVulnerabilityFeedbackDismissalPath,
            },
          },
        });

        await waitForPromises();

        // Click on the toggle button to expand data
        wrapper.findByRole('button', { name: 'Show details' }).trigger('click');
        await nextTick();

        // Second one is for the dynamic scroller
        await nextTick();

        // Click on the vulnerability name
        wrapper.findAllByText('Password leak').at(0).trigger('click');
        await nextTick();

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
    });

    describe('undo dismissing finding', () => {
      const feedbackDismissalPath = '/-/vulnerability/feedback';

      beforeEach(async () => {
        await createComponentExpandWidgetAndOpenModal({
          mockDataProps: {
            state: 'dismissed',
            dismissal_feedback: {
              destroy_vulnerability_feedback_dismissal_path: feedbackDismissalPath,
              author: {}, // This is required to because `modal.vue` file needs this object. Passing undefined causes the tests to fail.
            },
          },
          mrProps: {
            createVulnerabilityFeedbackDismissalPath,
          },
        });
      });

      it('handles undoing dismissing a finding - success', async () => {
        mockAxios.onDelete(feedbackDismissalPath).replyOnce(HTTP_STATUS_OK);

        findModal().vm.$emit('revertDismissVulnerability');

        await waitForPromises();

        expect(emitSpy).toHaveBeenCalledWith(BV_HIDE_MODAL, 'modal-mrwidget-security-issue');

        // The dismissal_feedback object should be set back to `null`.
        expect(findModal().props('modal').vulnerability.dismissal_feedback).toBe(null);
      });

      it('handles undoing dismissing a finding - error', async () => {
        mockAxios.onDelete(feedbackDismissalPath).replyOnce(HTTP_STATUS_BAD_REQUEST);

        findModal().vm.$emit('revertDismissVulnerability');

        await waitForPromises();

        expect(findModal().props('modal').error).toBe(
          'There was an error reverting the dismissal. Please try again.',
        );
      });
    });
  });
});
