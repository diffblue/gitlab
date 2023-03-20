<script>
import { GlButton, GlFormCheckbox, GlSkeletonLoader, GlSprintf, GlIcon } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import convertReportType from 'ee/vue_shared/security_reports/store/utils/convert_report_type';
import getPrimaryIdentifier from 'ee/vue_shared/security_reports/store/utils/get_primary_identifier';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  getCreatedIssueForVulnerability,
  getDismissalTransitionForVulnerability,
} from 'ee/vue_shared/security_reports/components/helpers';
import VulnerabilityActionButtons from './vulnerability_action_buttons.vue';
import VulnerabilityIssueLink from './vulnerability_issue_link.vue';

export default {
  name: 'SecurityDashboardTableRow',
  components: {
    GlButton,
    GlFormCheckbox,
    GlSkeletonLoader,
    GlSprintf,
    GlIcon,
    SeverityBadge,
    VulnerabilityActionButtons,
    VulnerabilityIssueLink,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    vulnerability: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState('vulnerabilities', ['selectedVulnerabilities']),
    vulnerabilityIdentifier() {
      return getPrimaryIdentifier(this.vulnerability.identifiers, 'external_type');
    },
    vulnerabilityNamespace() {
      const { location } = this.vulnerability;
      return location && (location.image || location.file || location.path);
    },
    dismissalData() {
      return this.glFeatures.deprecateVulnerabilitiesFeedback
        ? getDismissalTransitionForVulnerability(this.vulnerability)
        : this.vulnerability.dismissal_feedback;
    },
    dismissalComment() {
      // state_transitions has a comment string, dismissal_feedback has a comment_details object.
      return this.glFeatures.deprecateVulnerabilitiesFeedback
        ? this.dismissalData?.comment
        : this.dismissalData?.comment_details;
    },
    issueData() {
      return this.glFeatures.deprecateVulnerabilitiesFeedback
        ? getCreatedIssueForVulnerability(this.vulnerability)
        : this.vulnerability.issue_feedback;
    },
    hasIssue() {
      // Issues can be deleted. After an issue is deleted, issue_feedback will still be an object, but it won't have
      // an issue_iid. issue_links however will remove the object from the array. Once we enable and remove the
      // deprecate_vulnerabilities_feedback feature flag, it's no longer necessary to check for issue_iid, and this
      // computed property can be deleted in favor of checking whether issueData is truthy instead.
      return Boolean(this.issueData?.issue_iid);
    },
    canDismissVulnerability() {
      const path = this.vulnerability.create_vulnerability_feedback_dismissal_path;
      return Boolean(path);
    },
    canCreateIssue() {
      const {
        create_vulnerability_feedback_issue_path: createGitLabIssuePath,
        create_jira_issue_url: createJiraIssueUrl,
      } = this.vulnerability;

      return Boolean(createGitLabIssuePath || createJiraIssueUrl) && !this.hasIssue;
    },
    extraIdentifierCount() {
      const { identifiers } = this.vulnerability;

      if (!identifiers) {
        return 0;
      }

      return identifiers.length - 1;
    },
    isSelected() {
      return Boolean(this.selectedVulnerabilities[this.vulnerability.id]);
    },
    shouldShowExtraIdentifierCount() {
      return this.extraIdentifierCount > 0;
    },
    useConvertReportType() {
      return convertReportType(this.vulnerability.report_type);
    },
    vulnerabilityVendor() {
      return this.vulnerability.scanner?.vendor;
    },
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'setModalData',
      'selectVulnerability',
      'deselectVulnerability',
    ]),
    toggleVulnerability() {
      if (this.isSelected) {
        return this.deselectVulnerability(this.vulnerability);
      }
      return this.selectVulnerability(this.vulnerability);
    },
    openModal(payload) {
      this.setModalData(payload);
      this.$root.$emit(BV_SHOW_MODAL, VULNERABILITY_MODAL_ID);
    },
  },
};
</script>

<template>
  <div
    class="gl-responsive-table-row p-2"
    :class="{ dismissed: dismissalData, 'gl-bg-blue-50': isSelected }"
  >
    <div class="table-section section-5">
      <gl-form-checkbox
        :checked="isSelected"
        :inline="true"
        class="my-0 ml-1 mr-3"
        data-qa-selector="security_finding_checkbox"
        :data-qa-finding-name="vulnerability.name"
        @change="toggleVulnerability"
      />
    </div>

    <div class="table-section section-15">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Severity') }}</div>
      <div class="table-mobile-content">
        <severity-badge
          v-if="vulnerability.severity"
          :severity="vulnerability.severity"
          class="text-right text-md-left"
        />
      </div>
    </div>

    <div class="table-section flex-grow-1">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Vulnerability') }}</div>
      <div
        class="table-mobile-content gl-white-space-normal"
        data-qa-selector="vulnerability_info_content"
      >
        <gl-skeleton-loader v-if="isLoading" :lines="2" />
        <template v-else>
          <gl-button
            ref="vulnerability-title"
            class="text-body gl-display-grid"
            button-text-classes="gl-text-left gl-white-space-normal! gl-pr-4!"
            variant="link"
            data-qa-selector="security_finding_name_button"
            :data-qa-status-description="vulnerability.name"
            @click="openModal({ vulnerability })"
            >{{ vulnerability.name }}</gl-button
          >
          <span v-if="dismissalData" data-testid="dismissal-label">
            <gl-icon v-if="dismissalComment" name="comment" class="text-warning" />
            <span class="text-uppercase">{{ s__('vulnerability|dismissed') }}</span>
          </span>
          <vulnerability-issue-link
            v-if="hasIssue"
            class="text-nowrap"
            :issue="issueData"
            :project-name="vulnerability.project.name"
          />

          <small v-if="vulnerabilityNamespace" class="gl-text-gray-500 gl-word-break-all">
            {{ vulnerabilityNamespace }}
          </small>
        </template>
      </div>
    </div>

    <div class="table-section gl-white-space-normal section-15">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Identifier') }}</div>
      <div class="table-mobile-content">
        <div class="gl-text-overflow-ellipsis gl-overflow-hidden" :title="vulnerabilityIdentifier">
          {{ vulnerabilityIdentifier }}
        </div>
        <div v-if="shouldShowExtraIdentifierCount" class="gl-text-gray-300">
          <gl-sprintf :message="__('+ %{count} more')">
            <template #count>
              {{ extraIdentifierCount }}
            </template>
          </gl-sprintf>
        </div>
      </div>
    </div>

    <div class="table-section section-15">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Scanner') }}</div>
      <div class="table-mobile-content">
        <div class="text-capitalize">
          {{ useConvertReportType }}
        </div>
        <div v-if="vulnerabilityVendor" class="gl-text-gray-300" data-testid="vulnerability-vendor">
          {{ vulnerabilityVendor }}
        </div>
      </div>
    </div>

    <div class="table-section section-20">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Actions') }}</div>
      <div class="table-mobile-content action-buttons d-flex justify-content-end">
        <vulnerability-action-buttons
          v-if="!isLoading"
          :vulnerability="vulnerability"
          :can-create-issue="canCreateIssue"
          :can-dismiss-vulnerability="canDismissVulnerability"
          :is-dismissed="Boolean(dismissalData)"
        />
      </div>
    </div>
  </div>
</template>
