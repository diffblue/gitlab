<script>
import { GlEmptyState, GlButton, GlIcon, GlSprintf } from '@gitlab/ui';
import { externalIssuesListEmptyStateI18n as i18n } from 'ee/external_issues_list/constants';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
    GlIcon,
    GlSprintf,
  },
  // The text injected is sanitized.
  inject: ['emptyStatePath', 'issueCreateUrl', 'emptyStateNoIssueText', 'createNewIssueText'],
  props: {
    currentState: {
      type: String,
      required: true,
    },
    issuesCount: {
      type: Object,
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasIssues() {
      return this.issuesCount[STATUS_OPEN] + this.issuesCount[STATUS_CLOSED] > 0;
    },
    emptyStateTitle() {
      const { titleWhenFilters, filterStateEmptyMessage } = i18n;

      if (this.hasFiltersApplied) {
        return titleWhenFilters;
      } else if (this.hasIssues) {
        return filterStateEmptyMessage[this.currentState];
      }

      return this.emptyStateNoIssueText;
    },
    emptyStateDescription() {
      const { descriptionWhenFilters, descriptionWhenNoIssues } = i18n;

      if (this.hasFiltersApplied) {
        return descriptionWhenFilters;
      } else if (!this.hasIssues) {
        return descriptionWhenNoIssues;
      }

      return '';
    },
  },
};
</script>

<template>
  <gl-empty-state :svg-path="emptyStatePath" :title="emptyStateTitle">
    <template v-if="!hasIssues || hasFiltersApplied" #description>
      <gl-sprintf :message="emptyStateDescription" />
    </template>
    <template v-if="!hasIssues" #actions>
      <gl-button :href="issueCreateUrl" target="_blank" variant="confirm">
        {{ createNewIssueText }}
        <gl-icon name="external-link" />
      </gl-button>
    </template>
  </gl-empty-state>
</template>
