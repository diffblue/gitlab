<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import MrWidgetRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import toast from '~/vue_shared/plugins/global_toast';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import FindingModal from 'ee/vue_shared/security_reports/components/modal.vue';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import findingQuery from 'ee/security_dashboard/graphql/queries/mr_widget_finding.graphql';
import dismissFindingMutation from 'ee/security_dashboard/graphql/mutations/dismiss_finding.mutation.graphql';
import revertFindingToDetectedMutation from 'ee/security_dashboard/graphql/mutations/revert_finding_to_detected.mutation.graphql';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { capitalizeFirstCharacter, convertToCamelCase } from '~/lib/utils/text_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { CRITICAL, HIGH } from '~/vulnerabilities/constants';
import download from '~/lib/utils/downloader';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import {
  getCreatedIssueForVulnerability,
  getDismissalTransitionForVulnerability,
} from 'ee/vue_shared/security_reports/components/helpers';
import SummaryText from './summary_text.vue';
import SummaryHighlights from './summary_highlights.vue';
import SecurityTrainingPromoWidget from './security_training_promo_widget.vue';
import { i18n, popovers, reportTypes } from './i18n';

export default {
  name: 'WidgetSecurityReports',
  components: {
    FindingModal,
    MrWidget,
    MrWidgetRow,
    SummaryText,
    SummaryHighlights,
    SecurityTrainingPromoWidget,
    GlBadge,
    GlButton,
    DynamicScroller,
    DynamicScrollerItem,
  },
  mixins: [glFeatureFlagsMixin()],
  i18n,
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      isCreatingIssue: false,
      isDismissingFinding: false,
      isCreatingMergeRequest: false,
      modalData: null,
      vulnerabilities: {
        collapsed: null,
        expanded: null,
      },
    };
  },

  apollo: {
    securityReportFinding: {
      manual: true,
      query: findingQuery,
      errorPolicy: 'none',
      variables() {
        return {
          fullPath: this.mr.sourceProjectFullPath,
          pipelineId: this.modalData.vulnerability.found_by_pipeline?.iid,
          uuid: this.modalData.vulnerability.uuid,
        };
      },
      error() {
        this.modalData.error = this.$options.i18n.findingLoadingError;
      },
      result({ data }) {
        const finding = data.project.pipeline.securityReportFinding;
        const { mergeRequest, stateComment, dismissedBy, dismissedAt, vulnerability } = finding;

        if (mergeRequest) {
          this.$set(this.modalData.vulnerability, 'hasMergeRequest', true);

          const mergeRequestData = {
            author: mergeRequest.author,
            merge_request_path: mergeRequest.webUrl,
            created_at: mergeRequest.createdAt,
            merge_request_iid: mergeRequest.iid,
          };

          if (this.glFeatures.deprecateVulnerabilitiesFeedback) {
            this.modalData.vulnerability.merge_request_links = [mergeRequestData];
          } else {
            this.modalData.vulnerability.merge_request_feedback = mergeRequestData;
          }
        }

        const issue = finding.issueLinks?.nodes.find((x) => x.linkType === 'CREATED')?.issue;
        if (issue) {
          this.$set(this.modalData.vulnerability, 'hasIssue', true);

          const issueData = {
            author: issue.author,
            created_at: issue.createdAt,
            issue_url: issue.webUrl,
            issue_iid: issue.iid,
            link_type: 'created',
          };

          if (this.glFeatures.deprecateVulnerabilitiesFeedback) {
            this.modalData.vulnerability.issue_links = [issueData];
          } else {
            this.modalData.vulnerability.issue_feedback = issueData;
          }
        }

        if (this.glFeatures.deprecateVulnerabilitiesFeedback) {
          this.modalData.vulnerability.state_transitions = vulnerability
            ? vulnerability.stateTransitions.nodes.map(convertObjectPropsToSnakeCase)
            : [];
        } else if (dismissedAt) {
          this.$set(this.modalData.vulnerability, 'dismissal_feedback', {
            comment_details: stateComment
              ? { comment: stateComment, comment_author: dismissedBy }
              : null,
            author: dismissedBy,
            created_at: finding.dismissedAt,
          });
        }
      },
      skip() {
        return !this.modalData;
      },
    },
  },

  computed: {
    helpPopovers() {
      return {
        SAST: {
          options: { title: popovers.SAST_TITLE },
          content: { text: popovers.SAST_TEXT, learnMorePath: this.mr.sastHelp },
        },
        DAST: {
          options: { title: popovers.DAST_TITLE },
          content: { text: popovers.DAST_TEXT, learnMorePath: this.mr.dastHelp },
        },
        SECRET_DETECTION: {
          options: { title: popovers.SECRET_DETECTION_TITLE },
          content: {
            text: popovers.SECRET_DETECTION_TEXT,
            learnMorePath: this.mr.secretDetectionHelp,
          },
        },
        CONTAINER_SCANNING: {
          options: { title: popovers.CONTAINER_SCANNING_TITLE },
          content: {
            text: popovers.CONTAINER_SCANNING_TEXT,
            learnMorePath: this.mr.containerScanningHelp,
          },
        },
        DEPENDENCY_SCANNING: {
          options: { title: popovers.DEPENDENCY_SCANNING_TITLE },
          content: {
            text: popovers.DEPENDENCY_SCANNING_TEXT,
            learnMorePath: this.mr.dependencyScanningHelp,
          },
        },
        API_FUZZING: {
          options: { title: popovers.API_FUZZING_TITLE },
          content: {
            learnMorePath: this.mr.apiFuzzingHelp,
          },
        },
        COVERAGE_FUZZING: {
          options: { title: popovers.COVERAGE_FUZZING_TITLE },
          content: {
            learnMorePath: this.mr.coverageFuzzingHelp,
          },
        },
      };
    },

    isCollapsible() {
      if (!this.vulnerabilities.collapsed) {
        return false;
      }

      return this.vulnerabilitiesCount > 0;
    },

    vulnerabilitiesCount() {
      return this.vulnerabilities.collapsed.reduce((counter, current) => {
        return counter + current.numberOfNewFindings + (current.fixed?.length || 0);
      }, 0);
    },

    highlights() {
      if (!this.vulnerabilities.collapsed) {
        return {};
      }

      const highlights = {
        [HIGH]: 0,
        [CRITICAL]: 0,
        other: 0,
      };

      // The data we receive from the API is something like:
      // [
      //  { scanner: "SAST", added: [{ id: 15, severity: 'critical' }] },
      //  { scanner: "DAST", added: [{ id: 15, severity: 'high' }] },
      //  ...
      // ]
      this.vulnerabilities.collapsed.forEach((report) =>
        this.highlightsFromReport(report, highlights),
      );

      return highlights;
    },

    totalNewVulnerabilities() {
      if (!this.vulnerabilities.collapsed) {
        return 0;
      }

      return this.vulnerabilities.collapsed.reduce((counter, current) => {
        return counter + (current.numberOfNewFindings || 0);
      }, 0);
    },

    statusIconName() {
      if (this.totalNewVulnerabilities > 0) {
        return 'warning';
      }

      return 'success';
    },

    canCreateIssue() {
      return Boolean(
        this.mr.createVulnerabilityFeedbackIssuePath ||
          this.modalData?.vulnerability?.create_jira_issue_url,
      );
    },

    canDismissFinding() {
      return Boolean(this.mr.createVulnerabilityFeedbackDismissalPath);
    },

    actionButtons() {
      return [
        {
          href: `${this.mr.pipeline.path}/security`,
          text: this.$options.i18n.fullReport,
          trackFullReportClicked: true,
        },
      ];
    },
  },
  methods: {
    handleIsLoading(value) {
      this.isLoading = value;
    },

    fetchCollapsedData() {
      // TODO: check if gl.mrWidgetData can be safely removed after we migrate to the
      // widget extension.
      const endpoints = [
        [this.mr.sastComparisonPathV2, 'SAST'],
        [this.mr.dastComparisonPathV2, 'DAST'],
        [this.mr.secretDetectionComparisonPathV2, 'SECRET_DETECTION'],
        [this.mr.apiFuzzingComparisonPathV2, 'API_FUZZING'],
        [this.mr.coverageFuzzingComparisonPathV2, 'COVERAGE_FUZZING'],
        [this.mr.dependencyScanningComparisonPathV2, 'DEPENDENCY_SCANNING'],
        [this.mr.containerScanningComparisonPathV2, 'CONTAINER_SCANNING'],
      ].filter(([endpoint, reportType]) => {
        const enabledReportsKeyName = convertToCamelCase(reportType.toLowerCase());
        return Boolean(endpoint) && this.mr.enabledReports[enabledReportsKeyName];
      });

      // The backend returns the cached finding objects. Let's remove them as they may cause
      // bugs. Instead, fetch the non-cached data when the finding modal is opened.
      const getFindingWithoutFeedback = (finding) => ({
        ...finding,
        dismissal_feedback: undefined,
        merge_request_feedback: undefined,
        issue_feedback: undefined,
      });

      return endpoints.map(([path, reportType]) => () => {
        const props = {
          reportType,
          reportTypeDescription: reportTypes[reportType],
          numberOfNewFindings: 0,
          numberOfFixedFindings: 0,
          added: [],
          fixed: [],
        };

        return axios
          .get(path)
          .then(({ data, headers = {}, status }) => {
            const added = data.added?.map?.(getFindingWithoutFeedback) || [];
            const fixed = data.fixed?.map?.(getFindingWithoutFeedback) || [];

            return {
              headers,
              status,
              data: {
                ...props,
                ...data,
                added,
                fixed,
                findings: [...added, ...fixed],
                numberOfNewFindings: added.length,
                numberOfFixedFindings: fixed.length,
                qaSelector: this.$options.qaSelectors[reportType],
              },
            };
          })
          .catch(({ headers = {}, status = 500 }) => ({
            headers,
            status,
            data: { ...props, error: true },
          }));
      });
    },

    highlightsFromReport(report, highlights = { [HIGH]: 0, [CRITICAL]: 0, other: 0 }) {
      // The data we receive from the API is something like:
      // [
      //  { scanner: "SAST", added: [{ id: 15, severity: 'critical' }] },
      //  { scanner: "DAST", added: [{ id: 15, severity: 'high' }] },
      //  ...
      // ]
      return report.added.reduce((acc, vuln) => {
        if (vuln.severity === HIGH) {
          acc[HIGH] += 1;
        } else if (vuln.severity === CRITICAL) {
          acc[CRITICAL] += 1;
        } else {
          acc.other += 1;
        }
        return acc;
      }, highlights);
    },

    statusIconNameReportType(report) {
      if (report.numberOfNewFindings > 0 || report.error) {
        return EXTENSION_ICONS.warning;
      }

      return EXTENSION_ICONS.success;
    },

    statusIconNameVulnerability(vuln) {
      return EXTENSION_ICONS[`severity${capitalizeFirstCharacter(vuln.severity)}`];
    },

    isDismissed(vuln) {
      return vuln.state === 'dismissed';
    },

    setModalData(finding) {
      this.modalData = {
        error: null,
        title: finding.name,
        vulnerability: finding,
        isShowingDeleteButtons: false,
      };

      this.isDismissingFinding = false;

      this.$root.$emit(BV_SHOW_MODAL, VULNERABILITY_MODAL_ID);
    },

    createNewIssue() {
      this.isCreatingIssue = true;
      const finding = this.modalData?.vulnerability;

      axios
        .post(this.mr.createVulnerabilityFeedbackIssuePath, {
          vulnerability_feedback: {
            feedback_type: 'issue',
            pipeline_id: this.mr.pipelineId,
            project_fingerprint: finding.project_fingerprint,
            finding_uuid: finding.uuid,
            category: finding.report_type,
            vulnerability_data: { ...finding, category: finding.report_type },
          },
        })
        .then(({ data }) => {
          const url = this.glFeatures.deprecateVulnerabilitiesFeedback
            ? getCreatedIssueForVulnerability(data).issue_url
            : data.issue_url;

          visitUrl(url);
        })
        .catch(() => {
          this.isCreatingIssue = false;
          this.modalData.error = s__(
            'ciReport|There was an error creating the issue. Please try again.',
          );
        });
    },

    dismissFinding(comment, toastMsg, errorMsg) {
      const finding = this.modalData?.vulnerability;

      this.isDismissingFinding = true;

      this.$apollo
        .mutate({
          mutation: dismissFindingMutation,
          refetchQueries: [findingQuery],
          variables: {
            uuid: finding.uuid,
            comment,
          },
        })
        .then(({ data }) => {
          const { errors } = data.securityFindingDismiss;

          if (errors.length > 0) {
            this.modalData.error = sprintf(
              s__('ciReport|There was an error dismissing the vulnerability: %{error}'),
              { error: errors[0] },
            );

            return;
          }

          this.modalData.vulnerability.state = 'dismissed';
          this.hideModal();

          toast(
            toastMsg ||
              sprintf(s__("SecurityReports|Dismissed '%{vulnerabilityName}'"), {
                vulnerabilityName: finding.name,
              }),
          );
        })
        .catch(() => {
          this.modalData.error =
            errorMsg ||
            s__('ciReport|There was an error dismissing the vulnerability. Please try again.');
        })
        .finally(() => {
          this.isDismissingFinding = false;
        });
    },

    revertDismissVulnerability() {
      this.isDismissingFinding = true;

      this.$apollo
        .mutate({
          mutation: revertFindingToDetectedMutation,
          refetchQueries: [findingQuery],
          variables: {
            uuid: this.modalData.vulnerability.uuid,
          },
        })
        .then(({ data }) => {
          const { errors } = data.securityFindingRevertToDetected;

          if (errors.length > 0) {
            this.modalData.error = sprintf(
              s__('ciReport|There was an error reverting the dismissal: %{error}'),
              { error: errors[0] },
            );

            return;
          }

          this.modalData.vulnerability.state = 'detected';
          this.modalData.vulnerability.dismissal_feedback = null;

          this.hideModal();
        })
        .catch(() => {
          this.modalData.error = s__(
            'ciReport|There was an error reverting the dismissal. Please try again.',
          );
        })
        .finally(() => {
          this.isDismissingFinding = false;
        });
    },

    openDismissalCommentBox() {
      this.$set(this.modalData, 'isCommentingOnDismissal', true);
    },

    closeDismissalCommentBox() {
      this.$set(this.modalData, 'isCommentingOnDismissal', false);
    },

    addDismissalComment(comment) {
      const finding = this.modalData.vulnerability;

      const isEditingDismissalContent = Boolean(
        this.glFeatures.deprecateVulnerabilitiesFeedback
          ? getDismissalTransitionForVulnerability(finding).comment
          : finding.dismissal_feedback?.comment_details?.comment,
      );

      const errorMsg = s__('SecurityReports|There was an error adding the comment.');
      const toastMsg = isEditingDismissalContent
        ? sprintf(s__("SecurityReports|Comment edited on '%{vulnerabilityName}'"), {
            vulnerabilityName: finding.name,
          })
        : sprintf(s__("SecurityReports|Comment added to '%{vulnerabilityName}'"), {
            vulnerabilityName: finding.name,
          });

      this.dismissFinding(comment, toastMsg, errorMsg);
    },

    hideDismissalDeleteButtons() {
      this.modalData.isShowingDeleteButtons = false;
    },

    showDismissalDeleteButtons() {
      this.modalData.isShowingDeleteButtons = true;
    },

    deleteDismissalComment() {
      const { vulnerability: finding } = this.modalData;
      const errorMsg = s__('SecurityReports|There was an error deleting the comment.');
      const toastMsg = sprintf(s__("SecurityReports|Comment deleted on '%{vulnerabilityName}'"), {
        vulnerabilityName: finding.name,
      });

      // This will cause the spinner to be displayed
      this.isDismissingFinding = true;

      this.dismissFinding(undefined, toastMsg, errorMsg);
    },

    createMergeRequest() {
      const finding = this.modalData.vulnerability;

      finding.target_branch = this.mr.sourceBranch;

      this.isCreatingMergeRequest = true;

      axios
        .post(this.mr.createVulnerabilityFeedbackMergeRequestPath, {
          vulnerability_feedback: {
            feedback_type: 'merge_request',
            category: finding.report_type,
            project_fingerprint: finding.project_fingerprint,
            finding_uuid: finding.uuid,
            vulnerability_data: { ...finding, category: finding.report_type },
          },
        })
        .then(({ data }) => {
          const url = this.glFeatures.deprecateVulnerabilitiesFeedback
            ? data.merge_request_links.at(-1).merge_request_path
            : data.merge_request_path;

          visitUrl(url);
        })
        .catch(() => {
          this.isCreatingMergeRequest = false;
          this.modalData.error = s__(
            'ciReport|There was an error creating the merge request. Please try again.',
          );
        });
    },

    downloadPatch() {
      download({
        fileData: this.modalData.vulnerability.remediations[0].diff,
        fileName: 'remediation.patch',
      });
    },

    hideModal() {
      this.$root.$emit(BV_HIDE_MODAL, VULNERABILITY_MODAL_ID);
    },

    clearModalData() {
      this.modalData = null;
    },
  },
  SEVERITY_LEVELS,
  widgetHelpPopover: {
    options: { title: i18n.helpPopoverTitle },
    content: {
      text: i18n.helpPopoverContent,
      learnMorePath: helpPagePath('user/application_security/index', {
        anchor: 'ultimate',
      }),
    },
  },
  qaSelectors: {
    SAST: 'sast_scan_report',
    DAST: 'dast_scan_report',
    DEPENDENCY_SCANNING: 'dependency_scan_report',
    CONTAINER_SCANNING: 'container_scan_report',
    COVERAGE_FUZZING: 'coverage_fuzzing_report',
    API_FUZZING: 'api_fuzzing_report',
  },
};
</script>

<template>
  <mr-widget
    v-if="!mr.isPipelineActive"
    v-model="vulnerabilities"
    :error-text="$options.i18n.error"
    :fetch-collapsed-data="fetchCollapsedData"
    :status-icon-name="statusIconName"
    :widget-name="$options.name"
    :is-collapsible="isCollapsible"
    :help-popover="$options.widgetHelpPopover"
    :action-buttons="actionButtons"
    multi-polling
    data-qa-selector="vulnerability_report_grouped"
    @is-loading="handleIsLoading"
  >
    <template #summary>
      <summary-text :total-new-vulnerabilities="totalNewVulnerabilities" :is-loading="isLoading" />
      <summary-highlights
        v-if="!isLoading && totalNewVulnerabilities > 0"
        :highlights="highlights"
      />
    </template>
    <template #content>
      <finding-modal
        v-if="modalData"
        :visible="true"
        :modal="modalData"
        :is-dismissing-vulnerability="isDismissingFinding"
        :is-creating-merge-request="isCreatingMergeRequest"
        :is-creating-issue="isCreatingIssue"
        :is-loading-additional-info="$apollo.queries.securityReportFinding.loading"
        :can-create-issue="canCreateIssue"
        :can-dismiss-vulnerability="canDismissFinding"
        @addDismissalComment="addDismissalComment"
        @createMergeRequest="createMergeRequest"
        @closeDismissalCommentBox="closeDismissalCommentBox"
        @openDismissalCommentBox="openDismissalCommentBox"
        @editVulnerabilityDismissalComment="openDismissalCommentBox"
        @deleteDismissalComment="deleteDismissalComment"
        @downloadPatch="downloadPatch"
        @revertDismissVulnerability="revertDismissVulnerability"
        @createNewIssue="createNewIssue"
        @dismissVulnerability="dismissFinding"
        @showDismissalDeleteButtons="showDismissalDeleteButtons"
        @hideDismissalDeleteButtons="hideDismissalDeleteButtons"
        @hidden="clearModalData"
      />
      <security-training-promo-widget
        :security-configuration-path="mr.securityConfigurationPath"
        :project-full-path="mr.sourceProjectFullPath"
      />
      <mr-widget-row
        v-for="report in vulnerabilities.collapsed"
        :key="report.reportType"
        :widget-name="$options.name"
        :level="2"
        :status-icon-name="statusIconNameReportType(report)"
        :help-popover="helpPopovers[report.reportType]"
        :data-testid="`report-${report.reportType}`"
      >
        <template #header>
          <div>
            <summary-text
              :total-new-vulnerabilities="report.numberOfNewFindings"
              :is-loading="false"
              :error="report.error"
              :scanner="report.reportTypeDescription"
              :data-testid="`${report.reportType}-report-header`"
              :data-qa-selector="report.qaSelector"
            />
            <summary-highlights
              v-if="report.numberOfNewFindings > 0"
              :highlights="highlightsFromReport(report)"
            />
          </div>
        </template>
        <template #body>
          <div
            v-if="report.numberOfNewFindings || report.numberOfFixedFindings"
            class="gl-mt-2 gl-w-full"
          >
            <dynamic-scroller
              :items="report.findings"
              :min-item-size="32"
              :style="{ maxHeight: '170px' }"
              data-testid="dynamic-content-scroller"
              key-field="uuid"
              class="gl-pr-5"
            >
              <template #default="{ item: vuln, active, index }">
                <dynamic-scroller-item :item="vuln" :active="active">
                  <strong
                    v-if="report.numberOfNewFindings > 0 && index === 0"
                    data-testid="new-findings-title"
                    class="gl-display-block gl-mt-2"
                    >{{ $options.i18n.new }}</strong
                  >
                  <strong
                    v-if="report.numberOfFixedFindings > 0 && report.numberOfNewFindings === index"
                    data-testid="fixed-findings-title"
                    class="gl-display-block gl-mt-2"
                    >{{ $options.i18n.fixed }}</strong
                  >
                  <mr-widget-row
                    :key="vuln.uuid"
                    :level="3"
                    :widget-name="$options.name"
                    :status-icon-name="statusIconNameVulnerability(vuln)"
                    class="gl-mt-2"
                  >
                    <template #body>
                      {{ $options.SEVERITY_LEVELS[vuln.severity] }}
                      <gl-button
                        variant="link"
                        class="gl-ml-2 gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis"
                        @click="setModalData(vuln)"
                        >{{ vuln.name }}</gl-button
                      >
                      <gl-badge v-if="isDismissed(vuln)" class="gl-ml-3">{{
                        $options.i18n.dismissed
                      }}</gl-badge>
                    </template>
                  </mr-widget-row>
                </dynamic-scroller-item>
              </template>
            </dynamic-scroller>
          </div>
        </template>
      </mr-widget-row>
    </template>
  </mr-widget>
</template>
