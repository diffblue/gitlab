<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import vulnerabilityStateMutations from 'ee/security_dashboard/graphql/mutate_vulnerability_state';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import StatusBadge from 'ee/vue_shared/security_reports/components/status_badge.vue';
import { createAlert } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_VULNERABILITY } from '~/graphql_shared/constants';
import axios from '~/lib/utils/axios_utils';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import download from '~/lib/utils/downloader';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import UsersCache from '~/lib/utils/users_cache';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { VULNERABILITY_STATE_OBJECTS, FEEDBACK_TYPES, HEADER_ACTION_BUTTONS } from '../constants';
import { normalizeGraphQLVulnerability, normalizeGraphQLLastStateTransition } from '../helpers';
import ResolutionAlert from './resolution_alert.vue';
import StatusDescription from './status_description.vue';

export default {
  name: 'VulnerabilityHeader',

  components: {
    GlLoadingIcon,
    GlButton,
    StatusBadge,
    ResolutionAlert,
    SplitButton,
    StatusDescription,
    VulnerabilityStateDropdownDeprecated: () =>
      import('./vulnerability_state_dropdown_deprecated.vue'),
    VulnerabilityStateDropdown: () => import('./vulnerability_state_dropdown.vue'),
  },

  mixins: [glFeatureFlagMixin()],

  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      isProcessingAction: false,
      isLoadingVulnerability: false,
      isLoadingUser: false,
      user: undefined,
    };
  },

  computed: {
    actionButtons() {
      const buttons = [];

      if (this.canCreateMergeRequest) {
        buttons.push(HEADER_ACTION_BUTTONS.mergeRequestCreation);
      }

      if (this.canDownloadPatch) {
        buttons.push(HEADER_ACTION_BUTTONS.patchDownload);
      }

      return buttons;
    },
    canDownloadPatch() {
      return (
        this.vulnerability.state !== VULNERABILITY_STATE_OBJECTS.resolved.state &&
        !this.mergeRequest &&
        this.hasRemediation
      );
    },
    hasIssue() {
      return Boolean(this.vulnerability.issueFeedback?.issueIid);
    },
    hasRemediation() {
      return this.vulnerability.remediations?.[0]?.diff?.length > 0;
    },
    mergeRequest() {
      return this.glFeatures.deprecateVulnerabilitiesFeedback
        ? this.vulnerability.mergeRequestLinks.at(-1)
        : this.vulnerability.mergeRequestFeedback;
    },
    canCreateMergeRequest() {
      return !this.mergeRequest && this.vulnerability.createMrUrl && this.hasRemediation;
    },
    showResolutionAlert() {
      return (
        this.vulnerability.resolvedOnDefaultBranch &&
        this.vulnerability.state !== VULNERABILITY_STATE_OBJECTS.resolved.state
      );
    },
    initialDismissalReason() {
      return this.vulnerability.stateTransitions?.at(-1)?.dismissalReason;
    },
  },

  watch: {
    'vulnerability.state': {
      immediate: true,
      handler(state) {
        const id = this.vulnerability[`${state}ById`];

        if (!id) {
          return;
        }

        this.isLoadingUser = true;

        UsersCache.retrieveById(id)
          .then((userData) => {
            this.user = userData;
          })
          .catch(() => {
            createAlert({
              message: s__('VulnerabilityManagement|Something went wrong, could not get user.'),
            });
          })
          .finally(() => {
            this.isLoadingUser = false;
          });
      },
    },
  },

  methods: {
    triggerClick(action) {
      const fn = this[action];
      if (typeof fn === 'function') fn();
    },

    async changeVulnerabilityState({ action, payload }) {
      this.isLoadingVulnerability = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: vulnerabilityStateMutations[action],
          variables: {
            id: convertToGraphQLId(TYPENAME_VULNERABILITY, this.vulnerability.id),
            ...payload,
          },
        });
        const [queryName] = Object.keys(data);

        this.$emit('vulnerability-state-change', {
          ...this.vulnerability,
          ...normalizeGraphQLVulnerability(data[queryName].vulnerability),
          ...normalizeGraphQLLastStateTransition(data[queryName].vulnerability, this.vulnerability),
        });
      } catch (error) {
        createAlert({
          message: {
            error,
            captureError: true,
            message: s__(
              'VulnerabilityManagement|Something went wrong, could not update vulnerability state.',
            ),
          },
        });
      } finally {
        this.isLoadingVulnerability = false;
      }
    },

    createMergeRequest() {
      this.isProcessingAction = true;

      const {
        reportType: category,
        pipeline: { sourceBranch },
        projectFingerprint,
        uuid,
      } = this.vulnerability;

      // note: this direct API call will be replaced when migrating the vulnerability details page to GraphQL
      // related epic: https://gitlab.com/groups/gitlab-org/-/epics/3657
      axios
        .post(this.vulnerability.createMrUrl, {
          vulnerability_feedback: {
            feedback_type: FEEDBACK_TYPES.MERGE_REQUEST,
            category,
            project_fingerprint: projectFingerprint,
            finding_uuid: uuid,
            vulnerability_data: {
              ...convertObjectPropsToSnakeCase(this.vulnerability),
              category,
              target_branch: sourceBranch,
            },
          },
        })
        .then(({ data }) => {
          const mergeRequestPath = this.glFeatures.deprecateVulnerabilitiesFeedback
            ? data.merge_request_links.at(-1).merge_request_path
            : data.merge_request_path;

          redirectTo(mergeRequestPath); // eslint-disable-line import/no-deprecated
        })
        .catch(() => {
          this.isProcessingAction = false;
          createAlert({
            message: s__(
              'ciReport|There was an error creating the merge request. Please try again.',
            ),
          });
        });
    },
    downloadPatch() {
      download({
        fileData: this.vulnerability.remediations[0].diff,
        fileName: `remediation.patch`,
      });
    },
  },
};
</script>

<template>
  <div data-qa-selector="vulnerability_header">
    <resolution-alert
      v-if="showResolutionAlert"
      :vulnerability-id="vulnerability.id"
      :default-branch-name="vulnerability.projectDefaultBranch"
    />
    <div class="detail-page-header">
      <div class="detail-page-header-body" data-testid="vulnerability-detail-body">
        <gl-loading-icon v-if="isLoadingVulnerability" size="sm" class="mr-2" />
        <status-badge v-else :state="vulnerability.state" class="gl-mr-4" />

        <status-description
          class="issuable-meta"
          :vulnerability="vulnerability"
          :user="user"
          :is-loading-vulnerability="isLoadingVulnerability"
          :is-loading-user="isLoadingUser"
        />
      </div>

      <div class="detail-page-header-actions align-items-center">
        <label class="mb-0 mx-2">{{ __('Status') }}</label>
        <gl-loading-icon v-if="isLoadingVulnerability" size="sm" class="d-inline" />
        <vulnerability-state-dropdown
          v-else-if="glFeatures.dismissalReason"
          :initial-state="vulnerability.state"
          :initial-dismissal-reason="initialDismissalReason"
          @change="changeVulnerabilityState"
        />
        <vulnerability-state-dropdown-deprecated
          v-else
          :initial-state="vulnerability.state"
          @change="changeVulnerabilityState"
        />
        <split-button
          v-if="actionButtons.length > 1"
          :buttons="actionButtons"
          :disabled="isProcessingAction"
          class="js-split-button"
          @createMergeRequest="createMergeRequest"
          @downloadPatch="downloadPatch"
        />
        <gl-button
          v-else-if="actionButtons.length > 0"
          class="ml-2"
          variant="confirm"
          category="secondary"
          :loading="isProcessingAction"
          @click="triggerClick(actionButtons[0].action)"
        >
          {{ actionButtons[0].name }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
