<script>
import { GlAlert, GlBadge, GlLoadingIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

import Note from 'ee/external_issues_show/components/note.vue';
import ExternalIssueAlert from 'ee/external_issues_show/components/external_issue_alert.vue';
import { fetchIssue } from 'ee/integrations/zentao/issues_show/api';
import ZentaoIssueSidebar from 'ee/integrations/zentao/issues_show/components/sidebar/zentao_issues_sidebar_root.vue';
import { STATUS_OPEN } from '~/issues/constants';

import IssuableShow from '~/vue_shared/issuable/show/components/issuable_show_root.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';

export default {
  name: 'ZenTaoIssuesShow',
  components: {
    GlAlert,
    GlBadge,
    GlLoadingIcon,
    ExternalIssueAlert,
    IssuableShow,
    ZentaoIssueSidebar,
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
          if (!issue) {
            throw new Error();
          }
          this.issue = convertObjectPropsToCamelCase(issue, { deep: true });
        })
        .catch(() => {
          this.errorMessage = this.$options.i18n.defaultErrorMessage;
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    externalIssueCommentId(id) {
      return `external_note_${id}`;
    },
  },
  i18n: {
    defaultErrorMessage: s__(
      'ZenTaoIntegration|Failed to load ZenTao issue. View the issue in ZenTao, or reload the page.',
    ),
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
      <external-issue-alert issue-tracker-name="ZenTao" :issue-url="issue.webUrl" />

      <issuable-show :issuable="issue" :enable-edit="false" :status-icon="statusIcon">
        <template #right-sidebar-items>
          <zentao-issue-sidebar :issue="issue" />
        </template>

        <template #discussion>
          <note
            v-for="comment in issue.comments"
            :id="externalIssueCommentId(comment.id)"
            :key="comment.id"
            :author-avatar-url="comment.author.avatarUrl"
            :author-web-url="comment.author.webUrl"
            :author-name="comment.author.name"
            :author-username="comment.author.username"
            :note-body-html="comment.bodyHtml"
            :note-created-at="comment.createdAt"
          >
            <template #badges>
              <gl-badge v-gl-tooltip="{ title: s__('ZenTaoIntegration|This is a ZenTao user.') }">
                {{ s__('ZenTaoIntegration|ZenTao user') }}
              </gl-badge>
            </template>
          </note>
        </template>
      </issuable-show>
    </template>
  </div>
</template>
