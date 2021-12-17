<script>
import { GlIcon } from '@gitlab/ui';
import { n__ } from '~/locale';
import RelatedIssuableItem from '~/issuable/components/related_issuable_item.vue';

export default {
  name: 'BlockingMergeRequestsBody',
  components: { RelatedIssuableItem, GlIcon },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    status: {
      type: String,
      required: true,
    },
    isNew: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    hiddenBlockingMRsText() {
      return n__(
        "%d merge request that you don't have access to.",
        "%d merge requests that you don't have access to.",
        this.issue.hiddenCount,
      );
    },
  },
};
</script>

<template>
  <div v-if="issue.hiddenCount" class="p-3 d-flex align-items-center">
    <gl-icon class="gl-mr-3" name="eye-slash" />
    {{ hiddenBlockingMRsText }}
  </div>
  <related-issuable-item
    v-else
    :id-key="issue.id"
    :display-reference="issue.reference"
    :title="issue.title"
    :milestone="issue.milestone"
    :assignees="issue.assignees"
    :created-at="issue.created_at"
    :closed-at="issue.closed_at"
    :merged-at="issue.merged_at"
    :path="issue.web_url"
    :state="issue.state"
    :is-merge-request="true"
    :pipeline-status="issue.head_pipeline && issue.head_pipeline.detailed_status"
    path-id-separator="!"
    :class="{ 'mr-merged': issue.state === 'merged' }"
    :grey-link-when-merged="true"
    class="w-100 p-xl-3"
  />
</template>
