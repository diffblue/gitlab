<script>
import { GlIcon, GlLoadingIcon } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import Api from 'ee/api';
import vulnerabilityDiscussionsQuery from 'ee/security_dashboard/graphql/queries/vulnerability_discussions.query.graphql';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import { createAlert } from '~/alert';
import { TYPENAME_VULNERABILITY } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { normalizeGraphQLNote } from '../helpers';
import GenericReportSection from './generic_report/report_section.vue';
import HistoryEntry from './history_entry.vue';
import RelatedIssues from './related_issues.vue';
import RelatedJiraIssues from './related_jira_issues.vue';
import StatusDescription from './status_description.vue';

const TEN_SECONDS = 10000;

export default {
  name: 'VulnerabilityFooter',
  components: {
    GenericReportSection,
    SolutionCard,
    MergeRequestNote,
    HistoryEntry,
    RelatedIssues,
    RelatedJiraIssues,
    GlLoadingIcon,
    GlIcon,
    StatusDescription,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    createJiraIssueUrl: {
      default: '',
    },
  },
  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      discussionsLoading: true,
      discussions: [],
      lastFetchedDiscussionIndex: -1,
    };
  },
  apollo: {
    discussions: {
      query: vulnerabilityDiscussionsQuery,
      variables() {
        return { id: convertToGraphQLId(TYPENAME_VULNERABILITY, this.vulnerability.id) };
      },
      update: ({ vulnerability }) => {
        return (
          vulnerability?.discussions?.nodes.map((discussion) => ({
            ...discussion,
            notes: discussion.notes.nodes.map(normalizeGraphQLNote),
          })) || []
        );
      },
      result() {
        this.discussionsLoading = false;
        this.notifyHeaderForStateChangeIfRequired();
        this.startPolling();
        this.bindVisibilityListener();
      },
      error() {
        this.showGraphQLError();
      },
    },
  },
  computed: {
    project() {
      return {
        url: this.vulnerability.project.fullPath,
        value: this.vulnerability.project.fullName,
      };
    },
    solutionText() {
      const { solutionHtml, solution, remediations } = this.vulnerability;
      return solutionHtml || solution || remediations?.[0]?.summary;
    },
    canDownloadPatch() {
      return (
        !this.mergeRequest &&
        this.vulnerability.state !== VULNERABILITY_STATE_OBJECTS.resolved.state &&
        this.vulnerability.remediations?.[0]?.diff?.length > 0
      );
    },
    issueLinksEndpoint() {
      return Api.buildUrl(Api.vulnerabilityIssueLinksPath).replace(':id', this.vulnerability.id);
    },
    vulnerabilityDetectionData() {
      const { pipeline } = this.vulnerability;

      // manually submitted vulnerabilities have no associated pipeline, in that case we don't display the detection data
      return pipeline
        ? {
            state: 'detected',
            pipeline,
          }
        : null;
    },
    mergeRequest() {
      return this.glFeatures.deprecateVulnerabilitiesFeedback
        ? this.vulnerability.mergeRequestLinks.at(-1)
        : this.vulnerability.mergeRequestFeedback;
    },
  },
  watch: {
    'vulnerability.state': {
      handler(newStatus, oldStatus) {
        if (newStatus !== oldStatus) {
          this.fetchDiscussions();
        }
      },
    },
  },
  beforeDestroy() {
    this.stopPolling();
    this.unbindVisibilityListener();
  },
  methods: {
    startPolling() {
      if (this.pollInterval) {
        return;
      }

      if (!Visibility.hidden()) {
        this.pollInterval = setInterval(this.fetchDiscussions, TEN_SECONDS);
      }
    },
    stopPolling() {
      if (typeof this.pollInterval !== 'undefined') {
        clearInterval(this.pollInterval);
        this.pollInterval = undefined;
      }
    },
    bindVisibilityListener() {
      if (this.visibilityListener) {
        return;
      }

      this.visibilityListener = Visibility.change(() => {
        if (Visibility.hidden()) {
          this.stopPolling();
        } else {
          this.startPolling();
        }
      });
    },
    unbindVisibilityListener() {
      if (typeof this.visibilityListener !== 'undefined') {
        Visibility.unbind(this.visibilityListener);
        this.visibilityListener = undefined;
      }
    },
    showGraphQLError() {
      createAlert({
        message: s__(
          'VulnerabilityManagement|Something went wrong while trying to retrieve the vulnerability history. Please try again later.',
        ),
      });
    },
    notifyHeaderForStateChangeIfRequired() {
      const lastItemIndex = this.discussions.length - 1;

      if (this.lastFetchedDiscussionIndex === lastItemIndex) {
        return;
      }

      // Do not notify on page load, or first mount.
      if (this.lastFetchedDiscussionIndex !== -1) {
        this.$emit('vulnerability-state-change');
      }

      this.lastFetchedDiscussionIndex = lastItemIndex;
    },
    async fetchDiscussions() {
      try {
        await this.$apollo.queries.discussions.refetch();
      } catch {
        this.showGraphQLError();
      }
    },
  },
};
</script>
<template>
  <div data-qa-selector="vulnerability_footer">
    <solution-card
      v-if="solutionText"
      class="md gl-my-6"
      :solution-text="solutionText"
      :can-download-patch="canDownloadPatch"
    />
    <generic-report-section
      v-if="vulnerability.details"
      class="md gl-mt-6"
      :details="vulnerability.details"
    />
    <div v-if="mergeRequest" class="card gl-mt-5">
      <merge-request-note :feedback="mergeRequest" :project="project" class="card-body" />
    </div>
    <related-jira-issues v-if="createJiraIssueUrl" class="gl-mt-6" />
    <related-issues
      v-else
      :endpoint="issueLinksEndpoint"
      :can-modify-related-issues="vulnerability.canModifyRelatedIssues"
      :project-path="project.url"
      :help-path="vulnerability.relatedIssuesHelpPath"
    />
    <div v-if="vulnerabilityDetectionData" class="notes" data-testid="detection-note">
      <div class="system-note gl-display-flex gl-align-items-center gl-p-0! gl-mt-6!">
        <div
          class="gl-float-left gl--flex-center gl-rounded-full gl-mt-n1 gl-ml-2 gl-w-6 gl-h-6 gl-bg-gray-50 gl-text-gray-600 gl-m-0!"
        >
          <gl-icon name="search-dot" class="circle-icon-container" />
        </div>
        <status-description
          :vulnerability="vulnerabilityDetectionData"
          :is-state-bolded="true"
          class="gl-ml-5"
        />
      </div>
    </div>
    <hr />
    <gl-loading-icon v-if="discussionsLoading" />
    <div v-else-if="discussions.length" class="notes discussion-body">
      <history-entry
        v-for="discussion in discussions"
        :key="discussion.id"
        :discussion="discussion"
        @onCommentUpdated="fetchDiscussions"
      />
    </div>
  </div>
</template>
