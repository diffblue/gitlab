<script>
import { GlButton } from '@gitlab/ui';
import axios from 'axios';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import { joinPaths, redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { sprintf, __, s__ } from '~/locale';
import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import { PathIdSeparator } from '~/related_issues/constants';
import RelatedIssuesStore from '~/related_issues/stores/related_issues_store';
import { RELATED_ISSUES_ERRORS } from '../constants';
import { getFormattedIssue, getAddRelatedIssueRequestParams } from '../helpers';

export default {
  name: 'VulnerabilityRelatedIssues',
  components: {
    RelatedIssuesBlock,
    GlButton,
  },
  inject: {
    vulnerabilityId: {
      default: 0,
    },
    projectFingerprint: {
      default: '',
    },
    newIssueUrl: {
      default: '',
    },
    reportType: {
      default: '',
    },
    issueTrackingHelpPath: {
      default: '',
    },
    permissionsHelpPath: {
      default: '',
    },
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    canModifyRelatedIssues: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    this.store = new RelatedIssuesStore();

    return {
      isProcessingAction: false,
      state: this.store.state,
      isFetching: false,
      isSubmitting: false,
      isFormVisible: false,
      errorCreatingIssue: false,
      inputValue: '',
    };
  },
  computed: {
    vulnerabilityProjectId() {
      return this.projectPath.replace(/^\//, ''); // Remove the leading slash, i.e. '/root/test' -> 'root/test'.
    },
    isIssueAlreadyCreated() {
      return Boolean(this.state.relatedIssues.find((i) => i.lockIssueRemoval));
    },
    canCreateIssue() {
      return !this.isIssueAlreadyCreated && !this.isFetching && Boolean(this.newIssueUrl);
    },
  },
  created() {
    this.fetchRelatedIssues();
  },
  methods: {
    createIssue() {
      this.isProcessingAction = true;
      redirectTo(this.newIssueUrl, { params: { vulnerability_id: this.vulnerabilityId } }); // eslint-disable-line import/no-deprecated
    },
    toggleFormVisibility() {
      this.isFormVisible = !this.isFormVisible;
    },
    resetForm() {
      this.isFormVisible = false;
      this.store.setPendingReferences([]);
      this.inputValue = '';
    },
    addRelatedIssue({ pendingReferences }) {
      this.processAllReferences(pendingReferences);
      this.isSubmitting = true;
      const errors = [];

      // The endpoint can only accept one issue, so we need to do a separate call for each pending reference.
      const requests = this.state.pendingReferences.map((reference) => {
        // note: this direct API call will be replaced when migrating the vulnerability details page to GraphQL
        // related epic: https://gitlab.com/groups/gitlab-org/-/epics/3657
        return axios
          .post(
            this.endpoint,
            getAddRelatedIssueRequestParams(reference, this.vulnerabilityProjectId),
          )
          .then(({ data }) => {
            const issue = getFormattedIssue(data.issue);
            // When adding an issue, the issue returned by the API doesn't have the vulnerabilityLinkId property; it's
            // instead in a separate ID property. We need to add it back in, or else the issue can't be deleted until
            // the page is refreshed.
            issue.vulnerabilityLinkId = issue.vulnerabilityLinkId ?? data.id;
            const index = this.state.pendingReferences.indexOf(reference);
            this.removePendingReference(index);
            this.store.addRelatedIssues(issue);
          })
          .catch(({ response }) => {
            errors.push({
              issueReference: reference,
              errorMessage: response.data?.message ?? RELATED_ISSUES_ERRORS.ISSUE_ID_ERROR,
            });
          });
      });

      return Promise.all(requests).then(() => {
        this.isSubmitting = false;
        const hasErrors = Boolean(errors.length);
        this.isFormVisible = hasErrors;

        if (hasErrors) {
          const messages = errors.map((error) => sprintf(RELATED_ISSUES_ERRORS.LINK_ERROR, error));
          createAlert({
            message: messages.join(' '),
          });
        }
      });
    },
    removeRelatedIssue(idToRemove) {
      const issue = this.state.relatedIssues.find(({ id }) => id === idToRemove);

      // note: this direct API call will be replaced when migrating the vulnerability details page to GraphQL
      // related epic: https://gitlab.com/groups/gitlab-org/-/epics/3657
      axios
        .delete(joinPaths(this.endpoint, issue.vulnerabilityLinkId.toString()))
        .then(() => {
          this.store.removeRelatedIssue(issue);
        })
        .catch(() => {
          createAlert({
            message: RELATED_ISSUES_ERRORS.UNLINK_ERROR,
          });
        });
    },
    fetchRelatedIssues() {
      this.isFetching = true;

      // note: this direct API call will be replaced when migrating the vulnerability details page to GraphQL
      // related epic: https://gitlab.com/groups/gitlab-org/-/epics/3657
      axios
        .get(this.endpoint)
        .then(({ data }) => {
          const issues = data.map(getFormattedIssue);
          this.store.setRelatedIssues(
            issues.map((i) => {
              const lockIssueRemoval = i.vulnerability_link_type === 'created';

              return {
                ...i,
                lockIssueRemoval,
                lockedMessage: lockIssueRemoval
                  ? s__('SecurityReports|Issues created from a vulnerability cannot be removed.')
                  : undefined,
              };
            }),
          );
        })
        .catch(() => {
          createAlert({
            message: __('An error occurred while fetching issues.'),
          });
        })
        .finally(() => {
          this.isFetching = false;
        });
    },
    addPendingReferences({ untouchedRawReferences, touchedReference = '' }) {
      this.store.addPendingReferences(untouchedRawReferences);
      this.inputValue = touchedReference;
    },
    removePendingReference(indexToRemove) {
      this.store.removePendingRelatedIssue(indexToRemove);
    },
    processAllReferences(value = '') {
      const rawReferences = value.split(/\s+/).filter((reference) => reference.trim().length > 0);
      this.addPendingReferences({ untouchedRawReferences: rawReferences });
    },
  },
  autoCompleteSources: gl?.GfmAutoComplete?.dataSources,
  issuableType: TYPE_ISSUE,
  pathIdSeparator: PathIdSeparator.Issue,
  i18n: {
    relatedIssues: __('Related issues'),
    createIssue: __('Create issue'),
    createIssueErrorTitle: __('Could not create issue'),
    createIssueErrorBody: s__(
      'SecurityReports|Ensure that %{trackingStart}issue tracking%{trackingEnd} is enabled for this project and you have %{permissionsStart}permission to create new issues%{permissionsEnd}.',
    ),
    addExistingIssue: __('Add existing issue'),
  },
};
</script>

<template>
  <div>
    <related-issues-block
      :help-path="helpPath"
      :is-fetching="isFetching"
      :is-submitting="isSubmitting"
      :related-issues="state.relatedIssues"
      :can-admin="canModifyRelatedIssues"
      :pending-references="state.pendingReferences"
      :is-form-visible="isFormVisible"
      :input-value="inputValue"
      :auto-complete-sources="$options.autoCompleteSources"
      :issuable-type="$options.issuableType"
      :path-id-separator="$options.pathIdSeparator"
      :show-categorized-issues="false"
      @toggleAddRelatedIssuesForm="toggleFormVisibility"
      @addIssuableFormInput="addPendingReferences"
      @addIssuableFormBlur="processAllReferences"
      @addIssuableFormSubmit="addRelatedIssue"
      @addIssuableFormCancel="resetForm"
      @pendingIssuableRemoveRequest="removePendingReference"
      @relatedIssueRemoveRequest="removeRelatedIssue"
    >
      <template #headerText>
        {{ $options.i18n.relatedIssues }}
      </template>
      <template #add-button-text>{{ $options.i18n.addExistingIssue }}</template>
      <template v-if="canCreateIssue" #header-actions>
        <gl-button
          ref="createIssue"
          size="small"
          data-qa-selector="create_issue_button"
          :loading="isProcessingAction"
          @click="createIssue"
        >
          {{ $options.i18n.createIssue }}
        </gl-button>
      </template>
    </related-issues-block>
  </div>
</template>
