<script>
import { GlAlert, GlBadge, GlLoadingIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

import Note from 'ee/external_issues_show/components/note.vue';
import ExternalIssueAlert from 'ee/external_issues_show/components/external_issue_alert.vue';
import { fetchIssue } from 'ee/integrations/jira/issues_show/api';

import JiraIssueSidebar from 'ee/integrations/jira/issues_show/components/sidebar/jira_issues_sidebar_root.vue';
import { issuableStatusText, STATUS_OPEN } from '~/issues/constants';
import IssuableShow from '~/vue_shared/issuable/show/components/issuable_show_root.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';

export default {
  name: 'JiraIssuesShow',
  components: {
    GlAlert,
    GlBadge,
    GlLoadingIcon,
    ExternalIssueAlert,
    IssuableShow,
    JiraIssueSidebar,
    Note,
  },
  directives: {
    GlTooltip,
  },
  inject: {
    issuesShowPath: {
      default: '',
    },
  },
  data() {
    return {
      isLoading: true,
      errorMessage: null,
      issue: {},
    };
  },
  computed: {
    isIssueOpen() {
      return this.issue.state === STATUS_OPEN;
    },
    statusBadgeText() {
      return issuableStatusText[this.issue.state];
    },
    statusIcon() {
      return this.isIssueOpen ? 'issue-open-m' : 'mobile-issue-close';
    },
  },
  mounted() {
    this.loadIssue();
  },
  methods: {
    loadIssue() {
      fetchIssue(this.issuesShowPath)
        .then((issue) => {
          this.issue = convertObjectPropsToCamelCase(issue, { deep: true });
        })
        .catch(() => {
          this.errorMessage = s__(
            'JiraService|Failed to load Jira issue. View the issue in Jira, or reload the page.',
          );
        })
        .finally(() => {
          this.isLoading = false;
        });
    },

    jiraIssueCommentId(id) {
      return `jira_note_${id}`;
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <gl-loading-icon v-if="isLoading" size="lg" />
    <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <template v-else>
      <external-issue-alert issue-tracker-name="Jira" :issue-url="issue.webUrl" />

      <issuable-show
        :issuable="issue"
        :enable-edit="false"
        :status-icon="statusIcon"
        status-icon-class="gl-sm-display-none"
      >
        <template #status-badge>{{ statusBadgeText }}</template>

        <template #right-sidebar-items="{ sidebarExpanded, toggleSidebar }">
          <jira-issue-sidebar
            :sidebar-expanded="sidebarExpanded"
            :issue="issue"
            @sidebar-toggle="toggleSidebar"
          />
        </template>

        <template #discussion>
          <note
            v-for="comment in issue.comments"
            :id="jiraIssueCommentId(comment.id)"
            :key="comment.id"
            :author-avatar-url="comment.author.avatarUrl"
            :author-web-url="comment.author.webUrl"
            :author-name="comment.author.name"
            :author-username="comment.author.username"
            :note-body-html="comment.bodyHtml"
            :note-created-at="comment.createdAt"
          >
            <template #badges>
              <gl-badge v-gl-tooltip="{ title: __('This is a Jira user.') }">
                {{ __('Jira user') }}
              </gl-badge>
            </template>
          </note>
        </template>
      </issuable-show>
    </template>
  </div>
</template>
