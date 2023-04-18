<script>
import {
  GlAvatar,
  GlButton,
  GlButtonGroup,
  GlLoadingIcon,
  GlFormGroup,
  GlFormTextarea,
  GlLink,
  GlModal,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import Api from 'ee/api';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import deploymentApprovalQuery from '../graphql/queries/deployment.query.graphql';
import MultipleApprovalRulesTable from './multiple_approval_rules_table.vue';

const MAX_CHARACTER_COUNT = 250;
const WARNING_CHARACTERS_LEFT = 30;
const DEPLOYMENT_STATUS_APPROVED = 'approved';

export default {
  components: {
    GlLoadingIcon,
    GlAvatar,
    GlButton,
    GlButtonGroup,
    GlFormGroup,
    GlFormTextarea,
    GlLink,
    GlModal,
    GlSprintf,
    MultipleApprovalRulesTable,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip,
  },
  inject: ['projectPath'],
  props: {
    /**
     * {
     *   name: String,
     *   tier: String,
     *   requiredApprovalCount
     * }
     */
    environment: {
      required: true,
      type: Object,
    },
    deploymentIid: {
      required: true,
      type: [Number, String],
    },
    showText: {
      required: false,
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      id: uniqueId('environment-approval'),
      commentId: uniqueId('environment-approval-comment'),
      loading: false,
      show: false,
      comment: '',
      project: {
        deployment: {
          userPermissions: { approveDeployment: false },
          approvalSummary: { rules: [] },
        },
      },
    };
  },
  apollo: {
    project: {
      query: deploymentApprovalQuery,
      skip() {
        return !this.show;
      },
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.deploymentIid,
        };
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
    title() {
      return sprintf(this.$options.i18n.title, {
        deploymentIid: this.deploymentIid,
      });
    },
    deployment() {
      return this.project?.deployment;
    },
    projectId() {
      return getIdFromGraphQLId(this.project?.id);
    },
    deploymentId() {
      return getIdFromGraphQLId(this.deployment.id);
    },
    buttonTitle() {
      return this.showText ? '' : this.$options.i18n.button;
    },
    needsApproval() {
      return this.totalApprovals > 0;
    },
    totalApprovals() {
      return this.environment.requiredApprovalCount;
    },
    currentApprovals() {
      return this.totalApprovals - this.deployment.pendingApprovalCount;
    },
    currentUserHasApproved() {
      return this.approvals.find(({ user }) => user.username === gon.current_username);
    },
    canApproveDeployment() {
      const isApprovalsNeeded =
        this.deployment.pendingApprovalCount > 0 ||
        this.deployment.approvalSummary.totalPendingApprovalCount > 0;
      return (
        this.deployment.userPermissions.approveDeployment &&
        !this.currentUserHasApproved &&
        isApprovalsNeeded
      );
    },
    deployableName() {
      return this.deployment.job?.name;
    },
    isCommentValid() {
      return this.comment.length <= MAX_CHARACTER_COUNT;
    },
    commentCharacterCountClasses() {
      return {
        'gl-text-orange-500':
          this.remainingCharacterCount <= WARNING_CHARACTERS_LEFT &&
          this.remainingCharacterCount >= 0,
        'gl-text-red-500': this.remainingCharacterCount < 0,
      };
    },
    characterCountTooltip() {
      return this.isCommentValid
        ? this.$options.i18n.charactersLeft
        : this.$options.i18n.charactersOverLimit;
    },
    remainingCharacterCount() {
      return MAX_CHARACTER_COUNT - this.comment.length;
    },
    approvals() {
      if (this.deployment.approvals?.length > 0) {
        // return unified approvals if exist (being deprecated)
        return this.deployment.approvals;
      }

      // return multiple approval rules approvals otherwise
      const rules = this.deployment.approvalSummary?.rules || [];

      const multipleApprovalRulesApprovals = rules.flatMap((rule) => rule.approvals);

      return multipleApprovalRulesApprovals;
    },
    hasApprovalRules() {
      return this.deployment.approvalSummary?.rules?.length > 0;
    },
    actionPrimary() {
      return this.canApproveDeployment
        ? {
            text: this.$options.i18n.approve,
            attributes: { loading: this.loading, variant: 'confirm', ref: 'approve' },
          }
        : null;
    },
    actionSecondary() {
      return this.canApproveDeployment
        ? { text: this.$options.i18n.reject, attributes: { ref: 'reject', loading: this.loading } }
        : null;
    },
    actionCancel() {
      return this.canApproveDeployment ? null : { text: this.$options.i18n.cancel };
    },
  },
  methods: {
    showModal() {
      this.show = true;
    },
    approve() {
      return this.actOnDeployment(Api.approveDeployment.bind(Api));
    },
    reject() {
      return this.actOnDeployment(Api.rejectDeployment.bind(Api));
    },
    actOnDeployment(action) {
      this.loading = true;
      this.show = false;
      return action({
        id: this.projectId,
        deploymentId: this.deploymentId,
        comment: this.comment,
      })
        .then(() => {
          this.$emit('change');
        })
        .catch((err) => {
          if (err.response) {
            createAlert({ message: err.response.data.message });
          }
        })
        .finally(() => {
          this.loading = false;
        });
    },
    approvalText({ status, user }) {
      if ((status || '').toLowerCase() === DEPLOYMENT_STATUS_APPROVED) {
        if (user.username === gon.current_username) {
          return this.$options.i18n.approvalByMe;
        }

        return this.$options.i18n.approval;
      }

      if (user.username === gon.current_username) {
        return this.$options.i18n.rejectedByMe;
      }

      return this.$options.i18n.rejected;
    },
  },
  i18n: {
    button: s__('DeploymentApproval|Approval options'),
    title: s__('DeploymentApproval|Approve or reject deployment #%{deploymentIid}'),
    message: s__(
      'DeploymentApproval|Approving will run the manual job from deployment #%{deploymentIid}. Rejecting will fail the manual job.',
    ),
    environment: s__('DeploymentApproval|Environment: %{environment}'),
    tier: s__('DeploymentApproval|Deployment tier: %{tier}'),
    job: s__('DeploymentApproval|Manual job: %{jobName}'),
    current: s__('DeploymentApproval| Current approvals: %{current}'),
    approval: s__('DeploymentApproval|Approved %{time}'),
    approvalByMe: s__('DeploymentApproval|Approved by you %{time}'),
    rejected: s__('DeploymentApproval|Rejected %{time}'),
    rejectedByMe: s__('DeploymentApproval|Rejected by you %{time}'),
    charactersLeft: __('Characters left'),
    charactersOverLimit: __('Characters over limit'),
    commentLabel: __('Comment'),
    optional: __('(optional)'),
    description: __('Add comment...'),
    approve: __('Approve'),
    reject: __('Reject'),
    cancel: __('Cancel'),
  },
};
</script>
<template>
  <gl-button-group v-if="needsApproval">
    <gl-button
      :id="id"
      ref="button"
      v-gl-tooltip
      :loading="loading"
      :title="buttonTitle"
      icon="thumb-up"
      @click="showModal"
    >
      <template v-if="showText">
        {{ $options.i18n.button }}
      </template>
    </gl-button>
    <gl-modal
      v-model="show"
      :modal-id="id"
      :title="title"
      :action-primary="actionPrimary"
      :action-secondary="actionSecondary"
      :action-cancel="actionCancel"
      static
      modal-class="gl-text-gray-900"
      @primary="approve"
      @secondary="reject"
    >
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-absolute gl-top-half gl-left-50p" />
      <div v-else>
        <p>
          <gl-sprintf :message="$options.i18n.message">
            <template #deploymentIid>{{ deploymentIid }}</template>
          </gl-sprintf>
        </p>

        <div>
          <gl-sprintf :message="$options.i18n.environment">
            <template #environment>
              <span class="gl-font-weight-bold">{{ environment.name }}</span>
            </template>
          </gl-sprintf>
        </div>
        <div v-if="environment.tier">
          <gl-sprintf :message="$options.i18n.tier">
            <template #tier>
              <span class="gl-font-weight-bold">{{ environment.tier }}</span>
            </template>
          </gl-sprintf>
        </div>
        <div>
          <gl-sprintf v-if="deployableName" :message="$options.i18n.job">
            <template #jobName>
              <span class="gl-font-weight-bold">
                {{ deployableName }}
              </span>
            </template>
          </gl-sprintf>
        </div>

        <multiple-approval-rules-table
          v-if="hasApprovalRules"
          :rules="deployment.approvalSummary.rules"
          class="gl-my-4 gl-pt-4"
        />
        <div v-else class="gl-my-4 gl-pt-4">
          <gl-sprintf :message="$options.i18n.current">
            <template #current>
              <span class="gl-font-weight-bold"> {{ currentApprovals }}/{{ totalApprovals }}</span>
            </template>
          </gl-sprintf>
        </div>
        <template v-for="(approval, index) in approvals">
          <div :key="`user-${index}`" class="gl-display-flex gl-align-items-center">
            <gl-avatar :size="16" :src="approval.user.avatarUrl" class="gl-mr-2" />
            <gl-link :href="approval.user.webUrl" class="gl-mr-2">
              @{{ approval.user.username }}
            </gl-link>
          </div>
          <p :key="`approval-${index}`" class="gl-mb-0">
            <gl-sprintf :message="approvalText(approval)">
              <template #user>
                <gl-link :href="approval.user.webUrl">@{{ approval.user.username }}</gl-link>
              </template>
              <template #time><time-ago-tooltip :time="approval.createdAt" /></template>
            </gl-sprintf>
          </p>
          <blockquote
            v-if="approval.comment"
            :key="`comment-${index}`"
            class="gl-border-l-1 gl-border-l-solid gl-border-gray-200 gl-pl-2 gl-overflow-wrap-break"
          >
            {{ approval.comment }}
          </blockquote>
        </template>
        <div v-if="canApproveDeployment" class="gl-pt-4">
          <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
            <gl-form-group
              :label="$options.i18n.commentLabel"
              :label-for="commentId"
              :optional-text="$options.i18n.optional"
              class="gl-mb-0"
              optional
            >
              <gl-form-textarea
                :id="commentId"
                v-model="comment"
                :placeholder="$options.i18n.description"
                :state="isCommentValid"
              />
            </gl-form-group>
            <span
              v-gl-tooltip
              :title="characterCountTooltip"
              :class="commentCharacterCountClasses"
              class="gl-mt-2 gl-align-self-end"
            >
              {{ remainingCharacterCount }}
            </span>
          </div>
        </div>
      </div>
    </gl-modal>
  </gl-button-group>
</template>
