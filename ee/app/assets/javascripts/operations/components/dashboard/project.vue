<script>
import { isEmpty } from 'lodash';
import { mapActions } from 'vuex';
import { GlSprintf } from '@gitlab/ui';
import Alerts from 'ee/vue_shared/dashboards/components/alerts.vue';
import ProjectPipeline from 'ee/vue_shared/dashboards/components/project_pipeline.vue';
import TimeAgo from 'ee/vue_shared/dashboards/components/time_ago.vue';
import { STATUS_FAILED, STATUS_RUNNING } from 'ee/vue_shared/dashboards/constants';
import { __ } from '~/locale';
import Commit from '~/vue_shared/components/commit.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import ProjectHeader from './project_header.vue';

export default {
  components: {
    ProjectHeader,
    UserAvatarLink,
    Commit,
    Alerts,
    ProjectPipeline,
    TimeAgo,
    GlSprintf,
  },
  mixins: [timeagoMixin],
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  tooltips: {
    timeAgo: __('Finished'),
    triggerer: __('Triggerer'),
  },
  unlicensedMessages: {
    canUpgrade: __(
      "To see this project's operational details, %{linkStart}upgrade its group plan to Premium%{linkEnd}. You can also remove the project from the dashboard.",
    ),
    cannotUpgrade: __(
      "To see this project's operational details, contact an owner of group %{groupName} to upgrade the plan. You can also remove the project from the dashboard.",
    ),
  },
  computed: {
    hasPipelineFailed() {
      return (
        this.lastPipeline &&
        this.lastPipeline.details &&
        this.lastPipeline.details.status &&
        this.lastPipeline.details.status.group === STATUS_FAILED
      );
    },
    hasPipelineErrors() {
      return this.project.alert_count > 0;
    },
    cardClasses() {
      return {
        'dashboard-card-body-warning': !this.hasPipelineFailed && this.hasPipelineErrors,
        'dashboard-card-body-failed': this.hasPipelineFailed,
        'bg-secondary': !this.hasPipelineFailed && !this.hasPipelineErrors,
      };
    },
    noPipelineMessage() {
      return __('The branch for this project has no active pipeline configuration.');
    },
    user() {
      return this.lastPipeline && !isEmpty(this.lastPipeline.user) ? this.lastPipeline.user : null;
    },
    lastPipeline() {
      return !isEmpty(this.project.last_pipeline) ? this.project.last_pipeline : null;
    },
    commitRef() {
      return this.lastPipeline && !isEmpty(this.lastPipeline.ref)
        ? {
            ...this.lastPipeline.ref,
            ref_url: this.lastPipeline.ref.path,
          }
        : {};
    },
    finishedTime() {
      return (
        this.lastPipeline && this.lastPipeline.details && this.lastPipeline.details.finished_at
      );
    },
    finishedTimeTitle() {
      return this.tooltipTitle(this.finishedTime);
    },
    shouldShowTimeAgo() {
      return (
        this.lastPipeline &&
        this.lastPipeline.details &&
        this.lastPipeline.details.status &&
        this.lastPipeline.details.status.group !== STATUS_RUNNING &&
        this.finishedTime
      );
    },
  },
  methods: {
    ...mapActions(['removeProject']),
  },
};
</script>
<template>
  <div
    class="js-dashboard-project dashboard-card card border-0"
    data-qa-selector="dashboard_project_card"
  >
    <project-header
      :project="project"
      :has-pipeline-failed="hasPipelineFailed"
      :has-errors="hasPipelineErrors"
      @remove="removeProject"
    />

    <div
      v-if="project.upgrade_required"
      data-testid="dashboard-card-body"
      class="dashboard-card-body card-body bg-secondary"
    >
      <gl-sprintf v-if="project.upgrade_path" :message="$options.unlicensedMessages.canUpgrade">
        <template #link="{ content }">
          <gl-link :href="project.upgrade_path" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>

      <gl-sprintf v-else :message="$options.unlicensedMessages.cannotUpgrade">
        <template #groupName>{{ project.namespace.name }}</template>
      </gl-sprintf>
    </div>

    <div v-else :class="cardClasses" class="dashboard-card-body card-body">
      <div v-if="lastPipeline" class="row">
        <div class="col-1 align-self-center">
          <user-avatar-link
            v-if="user"
            :link-href="user.path"
            :img-src="user.avatar_url"
            :tooltip-text="user.name"
            :img-size="32"
          />
        </div>

        <div class="col-10 col-sm-7 pr-0 pl-5 align-self-center align-middle ci-table">
          <commit
            :tag="commitRef.tag"
            :commit-ref="commitRef"
            :short-sha="lastPipeline.commit.short_id"
            :commit-url="lastPipeline.commit.commit_url"
            :title="lastPipeline.commit.title"
            :author="lastPipeline.commit.author"
            :show-branch="true"
          />
        </div>

        <div class="col-sm-4 pl-0 text-right align-self-center d-none d-sm-block">
          <time-ago
            v-if="shouldShowTimeAgo"
            :time="finishedTime"
            :tooltip-text="$options.tooltips.timeAgo"
          />
          <alerts :count="project.alert_count" />
        </div>

        <div class="col-12">
          <project-pipeline :last-pipeline="lastPipeline" />
        </div>
      </div>

      <div v-else class="h-100 d-flex justify-content-center align-items-center">
        <div class="text-plain text-metric text-center bold w-75">
          {{ noPipelineMessage }}
        </div>
      </div>
    </div>
  </div>
</template>
