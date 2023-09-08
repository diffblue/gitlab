<script>
import { GlButton, GlSprintf, GlLink } from '@gitlab/ui';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import { __, s__ } from '~/locale';
import { DISMISSAL_REASONS } from 'ee/vulnerabilities/constants';
import { getDismissalNoteEventText } from './helpers';

export default {
  components: {
    EventItem,
    GlButton,
    GlSprintf,
    GlLink,
  },
  props: {
    feedback: {
      type: Object,
      required: true,
    },
    project: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isEditingDismissal: {
      type: Boolean,
      required: false,
      default: false,
    },
    isShowingDeleteButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
    showDismissalActions: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDismissingVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasDismissalReasonSupport: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    pipeline() {
      return this.feedback?.pipeline;
    },
    dismissalReason() {
      return DISMISSAL_REASONS[this.feedback.dismissalReason?.toLowerCase()];
    },
    eventText() {
      const { project, pipeline } = this;

      const hasPipeline = Boolean(pipeline?.path && pipeline?.id);
      const hasProject = Boolean(project?.url && project?.value);
      const hasDismissalReason = Boolean(this.dismissalReason);

      return getDismissalNoteEventText({ hasProject, hasPipeline, hasDismissalReason });
    },
    commentDetails() {
      return this.feedback.comment_details;
    },
    feedbackActionButtons() {
      return this.hasDismissalReasonSupport
        ? [
            {
              iconName: 'pencil',
              onClick: () => this.$emit('editDismissal'),
              title: s__('SecurityReports|Edit dismissal'),
            },
          ]
        : [];
    },
    commentActionButtons() {
      return [
        {
          iconName: 'pencil',
          onClick: () => this.$emit('editDismissal'),
          title: this.hasDismissalReasonSupport
            ? s__('SecurityReports|Edit dismissal')
            : __('Edit Comment'),
        },
        {
          iconName: 'remove',
          onClick: () => this.$emit('showDismissalDeleteButtons'),
          title: __('Delete Comment'),
        },
      ];
    },
    showFeedbackActions() {
      return this.hasDismissalReasonSupport && this.showDismissalActions && !this.commentDetails;
    },
  },
};
</script>

<template>
  <div>
    <event-item
      :action-buttons="feedbackActionButtons"
      :author="feedback.author"
      :created-at="feedback.created_at"
      :show-action-buttons="showFeedbackActions"
      icon-name="cancel"
      icon-class="ci-status-icon-pending"
    >
      <div v-if="feedback.created_at">
        <gl-sprintf :message="eventText">
          <template v-if="pipeline" #pipelineLink>
            <gl-link :href="pipeline.path" data-testid="pipeline-link">#{{ pipeline.id }}</gl-link>
          </template>
          <template v-if="project" #projectLink>
            <gl-link :href="project.url" data-testid="project-link">{{ project.value }}</gl-link>
          </template>
          <template #status="{ content }">{{ content }}</template>
          <template v-if="dismissalReason" #dismissalReason>
            {{ dismissalReason }}
          </template>
        </gl-sprintf>
      </div>
    </event-item>
    <template v-if="commentDetails && !isEditingDismissal">
      <hr class="my-3" />
      <event-item
        :action-buttons="commentActionButtons"
        :author="commentDetails.comment_author"
        :created-at="commentDetails.comment_timestamp"
        :show-right-slot="isShowingDeleteButtons"
        :show-action-buttons="showDismissalActions"
        icon-name="comment"
        icon-class="ci-status-icon-pending"
      >
        {{ commentDetails.comment }}

        <template #right-content>
          <div class="d-flex flex-grow-1 align-self-start flex-row-reverse">
            <gl-button category="primary" variant="danger" @click="$emit('deleteDismissalComment')">
              {{ __('Delete comment') }}
            </gl-button>
            <gl-button class="mr-2" @click="$emit('hideDismissalDeleteButtons')">
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </template>
      </event-item>
    </template>
  </div>
</template>
