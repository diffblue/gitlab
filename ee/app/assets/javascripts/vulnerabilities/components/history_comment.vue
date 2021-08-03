<script>
import { GlButton, GlSafeHtmlDirective as SafeHtml, GlLoadingIcon } from '@gitlab/ui';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import HistoryCommentEditor from './history_comment_editor.vue';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    EventItem,
    HistoryCommentEditor,
  },

  directives: {
    SafeHtml,
  },

  props: {
    comment: {
      type: Object,
      required: false,
      default: undefined,
    },
    discussionId: {
      type: String,
      required: false,
      default: undefined,
    },
    notesUrl: {
      type: String,
      required: true,
    },
  },

  data() {
    return {
      isEditingComment: false,
      isSavingComment: false,
      isDeletingComment: false,
      isConfirmingDeletion: false,
    };
  },

  computed: {
    actionButtons() {
      return [
        {
          iconName: 'pencil',
          onClick: this.showCommentInput,
          title: __('Edit Comment'),
        },
        {
          iconName: 'remove',
          onClick: this.showDeleteConfirmation,
          title: __('Delete Comment'),
        },
      ];
    },
    initialComment() {
      return this.comment && this.comment.note;
    },
    canEditComment() {
      return this.comment.currentUser?.canEdit;
    },
    noteHtml() {
      return this.isSavingComment ? undefined : this.comment.noteHtml;
    },
  },

  watch: {
    'comment.updatedAt': {
      handler() {
        this.isSavingComment = false;
      },
    },
  },

  methods: {
    showCommentInput() {
      this.isEditingComment = true;
    },
    getSaveConfig(note) {
      const isUpdatingComment = Boolean(this.comment);
      const method = isUpdatingComment ? 'put' : 'post';
      const url = isUpdatingComment ? this.comment.path : this.notesUrl;
      const data = { note: { note } };
      const emitName = isUpdatingComment ? 'onCommentUpdated' : 'onCommentAdded';

      // If we're saving a new comment, use the discussion ID in the request data.
      if (!isUpdatingComment) {
        data.in_reply_to_discussion_id = this.discussionId;
      }

      return { method, url, data, emitName };
    },
    saveComment(note) {
      this.isSavingComment = true;
      const { method, url, data, emitName } = this.getSaveConfig(note);

      // note: this direct API call will be replaced when migrating the vulnerability details page to GraphQL
      // related epic: https://gitlab.com/groups/gitlab-org/-/epics/3657
      axios({ method, url, data })
        .then(({ data: responseData }) => {
          this.isEditingComment = false;
          this.$emit(emitName, { response: responseData, comment: this.comment });
        })
        .catch(() => {
          createFlash({
            message: s__(
              'VulnerabilityManagement|Something went wrong while trying to save the comment. Please try again later.',
            ),
          });
        });
    },
    deleteComment() {
      this.isDeletingComment = true;
      const deleteUrl = this.comment.path;

      axios
        .delete(deleteUrl)
        .then(() => {
          this.$emit('onCommentDeleted', this.comment);
        })
        .catch(() =>
          createFlash({
            message: s__(
              'VulnerabilityManagement|Something went wrong while trying to delete the comment. Please try again later.',
            ),
          }),
        )
        .finally(() => {
          this.isDeletingComment = false;
        });
    },
    cancelEditingComment() {
      this.isEditingComment = false;
    },
    showDeleteConfirmation() {
      this.isConfirmingDeletion = true;
    },
    cancelDeleteConfirmation() {
      this.isConfirmingDeletion = false;
    },
  },
};
</script>

<template>
  <history-comment-editor
    v-if="isEditingComment"
    class="discussion-reply-holder"
    :initial-comment="initialComment"
    :is-saving="isSavingComment"
    @onSave="saveComment"
    @onCancel="cancelEditingComment"
  />

  <event-item
    v-else-if="comment"
    :id="comment.id"
    :author="comment.author"
    :created-at="comment.updatedAt"
    :show-action-buttons="canEditComment"
    :show-right-slot="isConfirmingDeletion"
    :action-buttons="actionButtons"
    icon-name="comment"
    icon-class="timeline-icon m-0"
    class="m-3"
  >
    <div v-safe-html="noteHtml" class="md">
      <gl-loading-icon size="sm" />
    </div>

    <template #right-content>
      <gl-button
        ref="confirmDeleteButton"
        variant="danger"
        :loading="isDeletingComment"
        @click="deleteComment"
      >
        {{ __('Delete') }}
      </gl-button>
      <gl-button
        ref="cancelDeleteButton"
        class="ml-2"
        :disabled="isDeletingComment"
        @click="cancelDeleteConfirmation"
      >
        {{ __('Cancel') }}
      </gl-button>
    </template>
  </event-item>

  <div v-else class="discussion-reply-holder">
    <button
      ref="addCommentButton"
      class="btn btn-text-field"
      type="button"
      @click="showCommentInput"
    >
      {{ s__('vulnerability|Add a comment') }}
    </button>
  </div>
</template>
