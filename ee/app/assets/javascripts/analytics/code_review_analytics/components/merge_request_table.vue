<script>
import { mapState } from 'vuex';
import { escape } from 'lodash';
import {
  GlTableLite,
  GlLink,
  GlIcon,
  GlAvatarLink,
  GlAvatar,
  GlTooltipDirective,
} from '@gitlab/ui';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { __, sprintf, n__ } from '~/locale';
import ApproversColumn from './approvers_column.vue';

export default {
  name: 'MergeRequestTable',
  components: {
    GlTableLite,
    GlLink,
    GlIcon,
    GlAvatarLink,
    GlAvatar,
    ApproversColumn,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState('mergeRequests', ['mergeRequests']),
  },
  methods: {
    getTimeAgoString(createdAt) {
      return sprintf(__('created %{timeAgo}'), {
        timeAgo: escape(getTimeago().format(createdAt)),
      });
    },
    showReviewTime(value) {
      return value !== null && value !== '';
    },
    formatReviewTime(hours) {
      if (hours >= 24) {
        const days = Math.floor(hours / 24);
        return n__('1 day', '%d days', days);
      } else if (hours >= 1 && hours < 24) {
        return n__('1 hour', '%d hours', hours);
      }

      return sprintf(__('%{lessThan} 1 hour'), { lessThan: '<' }, false);
    },
  },
  tableHeaderFields: [
    {
      key: 'mr_details',
      label: __('Merge Request'),
      thClass: 'w-30p',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'review_time',
      label: __('Review time'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'author',
      label: __('Author'),
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'approved_by',
      label: __('Approvers'),
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'notes_count',
      label: __('Comments'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'diff_stats',
      label: __('Commits'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
    {
      key: 'line_changes',
      label: __('Line changes'),
      class: 'text-right',
      tdClass: 'table-col d-flex align-items-center d-sm-table-cell',
    },
  ],
};
</script>

<template>
  <gl-table-lite
    class="my-3"
    :fields="$options.tableHeaderFields"
    :items="mergeRequests"
    stacked="sm"
  >
    <template #cell(mr_details)="items">
      <div class="d-flex flex-column flex-grow align-items-end align-items-sm-start">
        <div class="gl-max-w-34 str-truncated my-2">
          <gl-link :href="items.item.web_url" target="_blank" class="font-weight-bold text-plain">{{
            items.item.title
          }}</gl-link>
        </div>
        <ul class="horizontal-list list-items-separated text-secondary mb-0">
          <li>!{{ items.item.iid }}</li>
          <li>{{ getTimeAgoString(items.item.created_at) }}</li>
          <li v-if="items.item.milestone">
            <span class="d-flex align-items-center">
              <gl-icon name="clock" class="gl-mr-2" />
              {{ items.item.milestone.title }}
            </span>
          </li>
        </ul>
      </div>
    </template>

    <template #cell(review_time)="{ value }">
      <template v-if="showReviewTime(value)">
        <span v-text="formatReviewTime(value)"></span>
      </template>
      <template v-else> &ndash; </template>
    </template>

    <template #cell(author)="{ value }">
      <gl-avatar-link v-gl-tooltip target="_blank" :href="value.web_url" :title="value.name">
        <gl-avatar :size="24" :src="value.avatar_url" :entity-name="value.name" />
      </gl-avatar-link>
    </template>

    <template #cell(approved_by)="{ value }">
      <approvers-column
        :approvers="
          value && value.length
            ? value
            : [] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */
        "
      />
    </template>

    <template #cell(diff_stats)="{ value }">
      <span>{{ value.commits_count }}</span>
    </template>

    <template #cell(line_changes)="items">
      <span class="font-weight-bold cgreen"> +{{ items.item.diff_stats.additions }} </span>
      <span class="font-weight-bold cred"> -{{ items.item.diff_stats.deletions }} </span>
    </template>
  </gl-table-lite>
</template>
