<script>
import { GlIcon, GlLoadingIcon } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import Api from 'ee/api';
import vulnerabilityDiscussionsQuery from 'ee/security_dashboard/graphql/queries/vulnerability_discussions.query.graphql';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import createFlash from '~/flash';
import { TYPE_VULNERABILITY } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import { s__, __ } from '~/locale';
import initUserPopovers from '~/user_popovers';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GenericReportSection from './generic_report/report_section.vue';
import HistoryEntry from './history_entry.vue';
import RelatedIssues from './related_issues.vue';
import RelatedJiraIssues from './related_jira_issues.vue';
import StatusDescription from './status_description.vue';

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
      notesLoading: true,
      discussions: [],
      lastFetchedAt: null,
    };
  },
  apollo: {
    discussions: {
      query: vulnerabilityDiscussionsQuery,
      variables() {
        return { id: convertToGraphQLId(TYPE_VULNERABILITY, this.vulnerability.id) };
      },
      update: ({ vulnerability }) => {
        if (!vulnerability) {
          return [];
        }

        return vulnerability.discussions.nodes.map((d) => ({ ...d, notes: [] }));
      },
      result({ error }) {
        if (!this.poll && !error) {
          this.createNotesPoll();

          if (!Visibility.hidden()) {
            this.poll.makeRequest();
          }

          Visibility.change(() => {
            if (Visibility.hidden()) {
              this.poll.stop();
            } else {
              this.poll.restart();
            }
          });
        }
      },
      error() {
        this.notesLoading = false;

        createFlash({
          message: s__(
            'VulnerabilityManagement|Something went wrong while trying to retrieve the vulnerability history. Please try again later.',
          ),
        });
      },
    },
  },
  computed: {
    noteDictionary() {
      return this.discussions
        .flatMap((x) => x.notes)
        .reduce((acc, note) => {
          acc[note.id] = note;
          return acc;
        }, {});
    },
    project() {
      return {
        url: this.vulnerability.project.fullPath,
        value: this.vulnerability.project.fullName,
      };
    },
    solutionInfo() {
      const { solution, hasMr, remediations, state } = this.vulnerability;

      const remediation = remediations?.[0];
      const hasDownload = Boolean(
        state !== VULNERABILITY_STATE_OBJECTS.resolved.state && remediation?.diff?.length && !hasMr,
      );

      return {
        solution,
        remediation,
        hasDownload,
        hasMr,
      };
    },
    hasSolution() {
      return Boolean(this.solutionInfo.solution || this.solutionInfo.remediation);
    },
    issueLinksEndpoint() {
      return Api.buildUrl(Api.vulnerabilityIssueLinksPath).replace(':id', this.vulnerability.id);
    },
    vulnerabilityDetectionData() {
      return {
        state: 'detected',
        pipeline: this.vulnerability.pipeline,
      };
    },
  },
  updated() {
    this.$nextTick(() => {
      initUserPopovers(this.$el.querySelectorAll('.js-user-link'));
    });
  },
  beforeDestroy() {
    if (this.poll) {
      this.poll.stop();
    }
  },
  methods: {
    findDiscussion(id) {
      return this.discussions.find((d) => d.id === id);
    },
    createNotesPoll() {
      // note: this polling call will be replaced when migrating the vulnerability details page to GraphQL
      // related epic: https://gitlab.com/groups/gitlab-org/-/epics/3657
      this.poll = new Poll({
        resource: {
          fetchNotes: () =>
            axios.get(this.vulnerability.notesUrl, {
              headers: { 'X-Last-Fetched-At': this.lastFetchedAt },
            }),
        },
        method: 'fetchNotes',
        successCallback: ({ data: { notes, last_fetched_at: lastFetchedAt } }) => {
          this.updateNotes(convertObjectPropsToCamelCase(notes, { deep: true }));
          this.lastFetchedAt = lastFetchedAt;
          this.notesLoading = false;
        },
        errorCallback: () => {
          this.notesLoading = false;
          createFlash({
            message: __('Something went wrong while fetching latest comments.'),
          });
        },
      });
    },
    updateNotes(notes) {
      let shallEmitVulnerabilityChangedEvent;

      notes.forEach((note) => {
        const discussion = this.findDiscussion(note.discussionId);
        // If the note exists, update it.
        if (this.noteDictionary[note.id]) {
          discussion.notes = discussion.notes.map((curr) => (curr.id === note.id ? note : curr));
        }
        // If the note doesn't exist, but the discussion does, add the note to the discussion.
        else if (discussion) {
          discussion.notes.push(note);
        }
        // If the discussion doesn't exist, create it.
        else {
          this.discussions.push({
            id: note.discussionId,
            replyId: note.discussionId,
            notes: [note],
          });

          // If the vulnerability status has changed, the note will be a system note.
          // Emit an event that tells the header to refresh the vulnerability.
          if (note.system === true) {
            shallEmitVulnerabilityChangedEvent = true;
          }
        }
      });

      if (shallEmitVulnerabilityChangedEvent) {
        this.$emit('vulnerability-state-change');
      }
    },
  },
};
</script>
<template>
  <div data-qa-selector="vulnerability_footer">
    <solution-card v-if="hasSolution" v-bind="solutionInfo" />
    <generic-report-section
      v-if="vulnerability.details"
      class="md gl-mt-6"
      :details="vulnerability.details"
    />
    <div v-if="vulnerability.mergeRequestFeedback" class="card gl-mt-5">
      <merge-request-note
        :feedback="vulnerability.mergeRequestFeedback"
        :project="project"
        class="card-body"
      />
    </div>
    <related-jira-issues v-if="createJiraIssueUrl" class="gl-mt-6" />
    <related-issues
      v-else
      :endpoint="issueLinksEndpoint"
      :can-modify-related-issues="vulnerability.canModifyRelatedIssues"
      :project-path="project.url"
      :help-path="vulnerability.relatedIssuesHelpPath"
    />
    <div class="notes" data-testid="detection-note">
      <div class="system-note gl-display-flex gl-align-items-center gl-p-0! gl-mt-6!">
        <div class="timeline-icon gl-m-0!">
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
    <gl-loading-icon v-if="notesLoading" />
    <ul v-else-if="discussions.length" class="notes discussion-body">
      <history-entry
        v-for="discussion in discussions"
        :key="discussion.id"
        :discussion="discussion"
        :notes-url="vulnerability.notesUrl"
      />
    </ul>
  </div>
</template>
