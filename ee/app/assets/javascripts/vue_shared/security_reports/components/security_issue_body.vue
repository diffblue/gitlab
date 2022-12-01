<script>
/**
 * Renders Security Issues (SAST, DAST, Container
 * Scanning, Secret Detection) body text
 * [severity-badge] [name] in [link]:[line]
 */
import { GlBadge } from '@gitlab/ui';
import ModalOpenName from 'ee/ci/reports/components/modal_open_name.vue';
import ReportLink from '~/ci/reports/components/report_link.vue';
import SeverityBadge from './severity_badge.vue';

export default {
  name: 'SecurityIssueBody',
  components: {
    GlBadge,
    ReportLink,
    ModalOpenName,
    SeverityBadge,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    showReportLink() {
      return this.issue.report_type === 'sast' || this.issue.report_type === 'dependency_scanning';
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description gl-mt-2 gl-mb-2 gl-w-full">
    <div class="report-block-list-issue-description-text gl-display-flex gl-w-full">
      <severity-badge
        v-if="issue.severity"
        class="gl-display-inline-flex gl-align-items-center gl-mr-1"
        :severity="issue.severity"
      />
      <modal-open-name :issue="issue" :status="status" />
      <gl-badge v-if="issue.isDismissed" class="gl-ml-3" data-testid="dismissed-badge">
        {{ __('Dismissed') }}
      </gl-badge>
    </div>
    <report-link v-if="showReportLink && issue.path" :issue="issue" />
  </div>
</template>
