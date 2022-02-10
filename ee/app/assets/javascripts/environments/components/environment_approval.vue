<script>
import { GlButton, GlButtonGroup, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import Api from 'ee/api';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { createAlert } from '~/flash';
import { __, s__, sprintf } from '~/locale';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlLink,
    GlPopover,
    GlSprintf,
    TimeAgoTooltip,
  },
  inject: ['projectId'],
  props: {
    environment: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      id: uniqueId('environment-approval'),
      loading: false,
      show: false,
    };
  },
  computed: {
    title() {
      return sprintf(this.$options.i18n.title, {
        deploymentIid: this.deploymentIid,
      });
    },
    upcomingDeployment() {
      return this.environment?.upcomingDeployment;
    },
    needsApproval() {
      return this.upcomingDeployment.pendingApprovalCount > 0;
    },
    deploymentIid() {
      return this.upcomingDeployment.iid;
    },
    totalApprovals() {
      return this.environment.requiredApprovalCount;
    },
    currentApprovals() {
      return this.totalApprovals - this.upcomingDeployment.pendingApprovalCount;
    },
    currentUserHasApproved() {
      return this.upcomingDeployment?.approvals.find(
        ({ user }) => user.username === gon.current_username,
      );
    },
    canApproveDeployment() {
      return this.upcomingDeployment.canApproveDeployment && !this.currentUserHasApproved;
    },
    deployableName() {
      return this.upcomingDeployment.deployable?.name;
    },
  },
  methods: {
    showPopover() {
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
      action(this.projectId, this.upcomingDeployment.id)
        .catch((err) => {
          if (err.response) {
            createAlert({ message: err.response.data.message });
          }
        })
        .finally(() => {
          this.loading = false;
          this.$emit('change');
        });
    },
    approvalText({ user }) {
      if (user.username === gon.current_username) {
        return this.$options.i18n.approvalByMe;
      }

      return this.$options.i18n.approval;
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
    approval: s__('DeploymentApproval|Approved by %{user} %{time}'),
    approvalByMe: s__('DeploymentApproval|Approved by you %{time}'),
    approve: __('Approve'),
    reject: __('Reject'),
  },
};
</script>
<template>
  <gl-button-group v-if="needsApproval">
    <gl-button :id="id" ref="button" :loading="loading" icon="thumb-up" @click="showPopover">
      {{ $options.i18n.button }}
    </gl-button>
    <gl-popover :target="id" triggers="click blur" placement="top" :title="title" :show="show">
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

      <div class="gl-mt-4 gl-pt-4">
        <gl-sprintf :message="$options.i18n.current">
          <template #current>
            <span class="gl-font-weight-bold"> {{ currentApprovals }}/{{ totalApprovals }}</span>
          </template>
        </gl-sprintf>
      </div>
      <p v-for="(approval, index) in upcomingDeployment.approvals" :key="index">
        <gl-sprintf :message="approvalText(approval)">
          <template #user>
            <gl-link :href="approval.user.webUrl">@{{ approval.user.username }}</gl-link>
          </template>
          <template #time><time-ago-tooltip :time="approval.createdAt" /></template>
        </gl-sprintf>
      </p>
      <div v-if="canApproveDeployment" class="gl-mt-4 gl-pt-4">
        <gl-button ref="approve" :loading="loading" variant="confirm" @click="approve">
          {{ $options.i18n.approve }}
        </gl-button>
        <gl-button ref="reject" :loading="loading" @click="reject">
          {{ $options.i18n.reject }}
        </gl-button>
      </div>
    </gl-popover>
  </gl-button-group>
</template>
