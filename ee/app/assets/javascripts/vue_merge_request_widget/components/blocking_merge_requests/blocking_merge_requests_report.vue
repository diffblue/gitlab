<script>
import { GlSprintf } from '@gitlab/ui';
import { componentNames } from 'ee/ci/reports/components/issue_body';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import { n__, sprintf } from '~/locale';
import ReportSection from '~/ci/reports/components/report_section.vue';
import { status as reportStatus } from '~/ci/reports/constants';

export default {
  name: 'BlockingMergeRequestsReport',
  components: { ReportSection, GlSprintf },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  computed: {
    blockingMergeRequests() {
      return this.mr.blockingMergeRequests || {};
    },
    visibleMergeRequests() {
      return this.blockingMergeRequests.visible_merge_requests || {};
    },
    shouldRenderBlockingMergeRequests() {
      return this.blockingMergeRequests.total_count > 0;
    },
    openBlockingMergeRequests() {
      return this.visibleMergeRequests.opened || [];
    },
    closedBlockingMergeRequests() {
      return this.visibleMergeRequests.closed || [];
    },
    mergedBlockingMergeRequests() {
      return this.visibleMergeRequests.merged || [];
    },
    unmergedBlockingMergeRequests() {
      return Object.keys(this.visibleMergeRequests)
        .filter((state) => state !== STATUS_MERGED)
        .reduce(
          (unmergedBlockingMRs, state) =>
            state === STATUS_CLOSED
              ? [...this.visibleMergeRequests[state], ...unmergedBlockingMRs]
              : [...unmergedBlockingMRs, ...this.visibleMergeRequests[state]],
          [],
        );
    },
    unresolvedIssues() {
      return this.blockingMergeRequests.hidden_count > 0
        ? [
            { hiddenCount: this.blockingMergeRequests.hidden_count },
            ...this.unmergedBlockingMergeRequests,
          ]
        : this.unmergedBlockingMergeRequests;
    },
    isBlocked() {
      return (
        this.blockingMergeRequests.hidden_count > 0 || this.unmergedBlockingMergeRequests.length > 0
      );
    },
    closedCount() {
      return this.closedBlockingMergeRequests.length;
    },
    unmergedCount() {
      return this.unmergedBlockingMergeRequests.length + this.blockingMergeRequests.hidden_count;
    },
    blockedByText() {
      if (this.closedCount > 0 && this.closedCount === this.unmergedCount) {
        return sprintf(
          n__(
            'Depends on %{strongStart}%{closedCount} closed%{strongEnd} merge request.',
            'Depends on %{strongStart}%{closedCount} closed%{strongEnd} merge requests.',
            this.closedCount,
          ),
          { closedCount: this.closedCount },
        );
      }

      const mainText = n__(
        'Depends on %d merge request being merged',
        'Depends on %d merge requests being merged',
        this.unmergedCount,
      );

      return this.closedCount > 0
        ? `${mainText} %{strongStart}${n__(
            '(%d closed)',
            '(%d closed)',
            this.closedCount,
          )}%{strongEnd}`
        : mainText;
    },
    status() {
      return this.isBlocked ? reportStatus.ERROR : reportStatus.SUCCESS;
    },
  },
  componentNames,
};
</script>

<template>
  <report-section
    v-if="shouldRenderBlockingMergeRequests"
    class="mr-widget-border-top mr-report blocking-mrs-report"
    :status="status"
    :has-issues="true"
    :unresolved-issues="unresolvedIssues"
    :resolved-issues="mergedBlockingMergeRequests"
    :component="$options.componentNames.BlockingMergeRequestsBody"
    :show-report-section-status-icon="false"
    issues-ul-element-class="content-list"
    issues-list-container-class="p-0"
    issue-item-class="p-0"
  >
    <template #success>
      {{ __('All merge request dependencies have been merged') }}
      <span class="text-secondary gl-ml-1">
        {{
          sprintf(__('(%{mrCount} merged)'), {
            mrCount: blockingMergeRequests.total_count - unmergedBlockingMergeRequests.length,
          })
        }}
      </span>
    </template>
    <template #error>
      <span>
        <gl-sprintf :message="blockedByText">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </span>
    </template>
  </report-section>
</template>
