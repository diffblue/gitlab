<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NO_DATA_EMPTY_STATE_TYPE, NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE } from '../constants';

export default {
  name: 'IssuesAnalyticsEmptyState',
  components: {
    GlEmptyState,
  },
  inject: {
    noDataEmptyStateSvgPath: {
      type: String,
      default: '',
    },
    filtersEmptyStateSvgPath: {
      type: String,
      default: '',
    },
  },
  props: {
    emptyStateType: {
      type: String,
      required: true,
      validator: (type) =>
        [NO_DATA_EMPTY_STATE_TYPE, NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE].includes(type),
    },
  },
  computed: {
    emptyStateText() {
      return this.$options[this.emptyStateType];
    },
    emptyStateSvg() {
      return this.emptyStateType === NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE
        ? this.filtersEmptyStateSvgPath
        : this.noDataEmptyStateSvgPath;
    },
  },
  [NO_DATA_EMPTY_STATE_TYPE]: {
    title: s__('IssuesAnalytics|Get started with issue analytics'),
    description: s__(
      'IssuesAnalytics|Create issues for projects in your group to track and see metrics for them.',
    ),
  },
  [NO_DATA_WITH_FILTERS_EMPTY_STATE_TYPE]: {
    title: s__('IssuesAnalytics|Sorry, your filter produced no results'),
    description: s__(
      'IssuesAnalytics|To widen your search, change or remove filters in the filter bar above.',
    ),
  },
};
</script>

<template>
  <gl-empty-state v-bind="emptyStateText" :svg-path="emptyStateSvg" :svg-height="150" />
</template>
