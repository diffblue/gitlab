<script>
import { GlLink, GlAvatar } from '@gitlab/ui';
import { sprintf, __, n__ } from '~/locale';
import MetricColumn from './metric_column.vue';

export default {
  components: {
    GlLink,
    GlAvatar,
    MetricColumn,
  },
  props: {
    mergeRequest: {
      type: Object,
      required: true,
    },
    metricType: {
      type: String,
      required: true,
    },
    metricLabel: {
      type: String,
      required: true,
    },
  },
  computed: {
    mrId() {
      return `!${this.mergeRequest.iid}`;
    },
    commitCount() {
      return n__('%d commit', '%d commits', this.mergeRequest.commits_count);
    },
    locPerCommit() {
      return sprintf(__('%{count} LOC/commit'), { count: this.mergeRequest.loc_per_commit });
    },
    filesTouched() {
      return sprintf(__('%{count} files touched'), { count: this.mergeRequest.files_touched });
    },
    selectedMetric() {
      return this.mergeRequest[this.metricType];
    },
  },
  methods: {
    isNumber(metric) {
      return typeof metric === 'number';
    },
  },
};
</script>
<template>
  <div class="gl-responsive-table-row-layout gl-responsive-table-row">
    <div
      class="table-section section-50 d-flex flex-row-reverse flex-md-row justify-content-between justify-content-md-start js-mr-details"
    >
      <div class="d-flex mr-md-2">
        <gl-avatar :src="mergeRequest.author_avatar_url" :size="16" />
      </div>
      <div class="d-flex flex-column flex-grow overflow-auto gl-mr-1">
        <h5 class="item-title gl-max-w-34 my-0 d-block str-truncated">
          <gl-link :href="mergeRequest.merge_request_url" target="_blank">{{
            mergeRequest.title
          }}</gl-link>
        </h5>
        <ul class="horizontal-list list-items-separated text-secondary mb-0">
          <li>{{ mrId }}</li>
          <li v-if="isNumber(mergeRequest.commits_count)" ref="commitCount">{{ commitCount }}</li>
          <li v-if="isNumber(mergeRequest.loc_per_commit)" ref="locPerCommitCount">
            {{ locPerCommit }}
          </li>
          <li v-if="isNumber(mergeRequest.files_touched)" ref="filesTouchedCount">
            {{ filesTouched }}
          </li>
        </ul>
      </div>
    </div>
    <div class="table-section section-50 d-flex flex-row align-items-start js-mr-metrics">
      <metric-column
        type="days_to_merge"
        :value="mergeRequest.days_to_merge"
        :label="__('Time to merge')"
      />
      <metric-column :type="metricType" :value="selectedMetric" :label="metricLabel" />
    </div>
  </div>
</template>
