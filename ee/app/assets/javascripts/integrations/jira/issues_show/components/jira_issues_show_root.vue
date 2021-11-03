<script>
import {
  GlAlert,
  GlSprintf,
  GlLink,
  GlLoadingIcon,
  GlBadge,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import Note from 'ee/external_issues_show/components/note.vue';
import { fetchIssue, fetchIssueStatuses, updateIssue } from 'ee/integrations/jira/issues_show/api';

import JiraIssueSidebar from 'ee/integrations/jira/issues_show/components/sidebar/jira_issues_sidebar_root.vue';
import { IssuableStatus, IssuableStatusText } from '~/issue_show/constants';
import createFlash from '~/flash';
import IssuableShow from '~/issuable_show/components/issuable_show_root.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';

export default {
  name: 'JiraIssuesShow',
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    GlBadge,
    GlLoadingIcon,
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
      isLoadingStatus: false,
      isUpdatingLabels: false,
      isUpdatingStatus: false,
      errorMessage: null,
      issue: {},
      statuses: [],
    };
  },
  computed: {
    isIssueOpen() {
      return this.issue.state === IssuableStatus.Open;
    },
    statusBadgeClass() {
      return this.isIssueOpen ? 'status-box-open' : 'status-box-issue-closed';
    },
    statusBadgeText() {
      return IssuableStatusText[this.issue.state];
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

    onIssueLabelsUpdated(labels) {
      this.isUpdatingLabels = true;
      updateIssue(this.issue, { labels })
        .then((response) => {
          this.issue.labels = response.labels;
        })
        .catch(() => {
          createFlash({
            message: s__(
              'JiraService|Failed to update Jira issue labels. View the issue in Jira, or reload the page.',
            ),
          });
        })
        .finally(() => {
          this.isUpdatingLabels = false;
        });
    },
    onIssueStatusFetch() {
      this.isLoadingStatus = true;
      fetchIssueStatuses()
        .then((response) => {
          this.statuses = response;
        })
        .catch(() => {
          createFlash({
            message: s__(
              'JiraService|Failed to load Jira issue statuses. View the issue in Jira, or reload the page.',
            ),
          });
        })
        .finally(() => {
          this.isLoadingStatus = false;
        });
    },
    onIssueStatusUpdated(status) {
      this.isUpdatingStatus = true;
      updateIssue(this.issue, { status })
        .then((response) => {
          this.issue.status = response.status;
        })
        .catch(() => {
          createFlash({
            message: s__(
              'JiraService|Failed to update Jira issue status. View the issue in Jira, or reload the page.',
            ),
          });
        })
        .finally(() => {
          this.isUpdatingStatus = false;
        });
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
      <gl-alert
        variant="info"
        :dismissible="false"
        :title="s__('JiraService|This issue is synchronized with Jira')"
        class="gl-mb-2"
      >
        <gl-sprintf
          :message="
            s__(
              `JiraService|Not all data may be displayed here. To view more details or make changes to this issue, go to %{linkStart}Jira%{linkEnd}.`,
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="issue.webUrl" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>

      <issuable-show
        :issuable="issue"
        :enable-edit="false"
        :status-badge-class="statusBadgeClass"
        :status-icon="statusIcon"
      >
        <template #status-badge>{{ statusBadgeText }}</template>

        <template #right-sidebar-items="{ sidebarExpanded, toggleSidebar }">
          <jira-issue-sidebar
            :sidebar-expanded="sidebarExpanded"
            :issue="issue"
            :is-loading-status="isLoadingStatus"
            :is-updating-labels="isUpdatingLabels"
            :is-updating-status="isUpdatingStatus"
            :statuses="statuses"
            @issue-labels-updated="onIssueLabelsUpdated"
            @issue-status-fetch="onIssueStatusFetch"
            @issue-status-updated="onIssueStatusUpdated"
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
