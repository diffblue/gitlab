<script>
import jiraLogo from '@gitlab/svgs/dist/illustrations/logos/jira.svg?raw';
import { GlAlert, GlCard, GlIcon, GlLink, GlLoadingIcon, GlButton, GlSprintf } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import CreateJiraIssue from 'ee/vue_shared/security_reports/components/create_jira_issue.vue';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export const i18n = {
  cardHeading: s__('VulnerabilityManagement|Related Jira issues'),
  fetchErrorMessage: s__(
    'VulnerabilityManagement|Something went wrong while trying to fetch related Jira issues. Please check the %{linkStart}Jira integration settings%{linkEnd} and try again.',
  ),
  helpPageLinkLabel: s__('VulnerabilityManagement|Read more about related issues'),
  createNewIssueLinkText: s__('VulnerabilityManagement|Create Jira issue'),
  loadingStateLabel: s__('VulnerabilityManagement|Fetching linked Jira issues'),
};

export default {
  i18n,
  jiraLogo,
  components: {
    GlButton,
    CreateJiraIssue,
    GlAlert,
    GlCard,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    createJiraIssueUrl: {
      default: '',
    },
    relatedJiraIssuesPath: {
      default: '',
    },
    relatedJiraIssuesHelpPath: {
      default: '',
    },
    jiraIntegrationSettingsPath: {
      default: '',
    },
    vulnerabilityId: { required: true },
  },
  data() {
    return {
      isFetchingRelatedIssues: false,
      hasFetchIssuesError: false,
      isFetchErrorDismissed: false,
      relatedIssues: [],
      showCreateJiraIssueErrorAlertMessage: '',
      isCreateJiraIssueErrorDismissed: false,
      hasCreateJiraIssueError: false,
    };
  },
  computed: {
    shouldShowIssuesBody() {
      return this.isFetchingRelatedIssues || this.relatedIssues.length > 0;
    },
    issuesCount() {
      return this.isFetchingRelatedIssues ? '...' : this.relatedIssues.length;
    },
    lastIssue() {
      const [lastIssue] = this.relatedIssues.slice(-1);
      return lastIssue;
    },
    showFetchErrorAlert() {
      return this.hasFetchIssuesError && !this.isFetchErrorDismissed;
    },
    showCreateJiraIssueErrorAlert() {
      return this.hasCreateJiraIssueError && !this.isCreateJiraIssueErrorDismissed;
    },
  },
  created() {
    this.fetchRelatedIssues();
  },
  methods: {
    createJiraIssueErrorHandler(value) {
      this.hasCreateJiraIssueError = true;
      this.showCreateJiraIssueErrorAlertMessage = value;
    },
    // note: this direct API call will be replaced when migrating the vulnerability details page to GraphQL
    // related epic: https://gitlab.com/groups/gitlab-org/-/epics/3657
    async fetchRelatedIssues() {
      this.isFetchingRelatedIssues = true;
      try {
        const { data } = await axios.get(this.relatedJiraIssuesPath);
        if (Array.isArray(data)) {
          this.relatedIssues = data;
        }
      } catch {
        this.hasFetchIssuesError = true;
      } finally {
        this.isFetchingRelatedIssues = false;
      }
    },
  },
};
</script>
<template>
  <section>
    <gl-alert
      v-if="showFetchErrorAlert"
      variant="danger"
      class="gl-mb-4"
      @dismiss="isFetchErrorDismissed = true"
    >
      <gl-sprintf :message="$options.i18n.fetchErrorMessage">
        <template #link="{ content }">
          <gl-link :href="jiraIntegrationSettingsPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert
      v-if="showCreateJiraIssueErrorAlert"
      data-testid="create-jira-issue-error-alert"
      variant="danger"
      class="gl-mb-4"
      @dismiss="isCreateJiraIssueErrorDismissed = true"
    >
      {{ showCreateJiraIssueErrorAlertMessage }}
    </gl-alert>
    <gl-card
      :header-class="[
        'gl-py-3',
        'gl-display-flex',
        'gl-align-items-center',
        { 'gl-border-b-0': !shouldShowIssuesBody },
      ]"
      :body-class="['gl-bg-gray-10', { 'gl-display-none': !shouldShowIssuesBody }]"
    >
      <template #header>
        <h3 class="h5 gl-m-0">{{ $options.i18n.cardHeading }}</h3>
        <gl-link
          v-if="relatedJiraIssuesHelpPath"
          :aria-label="$options.i18n.helpPageLinkLabel"
          :href="relatedJiraIssuesHelpPath"
          target="_blank"
          class="gl-display-flex gl-align-items-center gl-ml-2 gl-text-gray-500"
        >
          <gl-icon name="question-o" :size="12" />
        </gl-link>
        <span
          class="gl-display-inline-flex gl-align-items-center gl-ml-4"
          data-testid="related-jira-issues-count"
        >
          <gl-icon name="issues" class="gl-mr-2 gl-text-gray-500" />
          {{ issuesCount }}
        </span>
        <create-jira-issue
          v-if="glFeatures.createVulnerabilityJiraIssueViaGraphql"
          class="gl-ml-auto"
          :vulnerability-id="vulnerabilityId"
          @create-jira-issue-error="createJiraIssueErrorHandler"
          @mutated="fetchRelatedIssues"
        />
        <gl-button
          v-else
          variant="confirm"
          category="secondary"
          :href="createJiraIssueUrl"
          icon="external-link"
          target="_blank"
          class="gl-ml-auto"
          data-testid="create-new-jira-issue-link"
          data-qa-selector="create_new_jira_issue_button"
        >
          {{ $options.i18n.createNewIssueLinkText }}
        </gl-button>
      </template>
      <section
        :hidden="!shouldShowIssuesBody"
        class="gl-p-0 gl-m-0"
        data-testid="related-jira-issues-section"
      >
        <gl-card body-class="gl-p-0">
          <gl-loading-icon
            v-if="isFetchingRelatedIssues"
            ref="loadingIcon"
            size="sm"
            :label="$options.i18n.loadingStateLabel"
            class="gl-my-3"
          />
          <ul class="gl-list-style-none gl-m-0 gl-p-0">
            <li
              v-for="issue in relatedIssues"
              :key="issue.created_at"
              class="gl-display-flex gl-align-items-center gl-py-3 gl-px-4"
              :class="
                issue !== lastIssue && [
                  'gl-border-b-1',
                  'gl-border-b-gray-100',
                  'gl-border-b-solid',
                ]
              "
            >
              <span
                v-safe-html="$options.jiraLogo"
                class="gl-min-h-6 gl-mr-5 gl-display-inline-flex gl-align-items-center"
              >
              </span>
              <gl-link
                :href="issue.web_url"
                target="_blank"
                data-qa-selector="jira_issue_link"
                :data-qa-issue-key="issue.references.relative"
                class="gl-text-gray-900"
              >
                {{ issue.title }}
              </gl-link>
              <span class="gl-ml-3 gl-text-gray-500">&num;{{ issue.references.relative }}</span>
            </li>
          </ul>
        </gl-card>
      </section>
    </gl-card>
  </section>
</template>
