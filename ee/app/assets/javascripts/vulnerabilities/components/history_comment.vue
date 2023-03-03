<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import createNoteMutation from 'ee/security_dashboard/graphql/mutations/note_create.mutation.graphql';
import destroyNoteMutation from 'ee/security_dashboard/graphql/mutations/note_destroy.mutation.graphql';
import updateNoteMutation from 'ee/security_dashboard/graphql/mutations/note_update.mutation.graphql';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import { createAlert } from '~/alert';
import {
  TYPENAME_NOTE,
  TYPENAME_DISCUSSION,
  TYPENAME_VULNERABILITY,
} from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
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

  inject: ['vulnerabilityId'],

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
      return this.comment?.body;
    },
    canEditComment() {
      return this.comment.userPermissions?.adminNote;
    },
    noteHtml() {
      return this.isSavingComment ? undefined : this.comment.bodyHtml;
    },
  },

  methods: {
    showCommentInput() {
      this.isEditingComment = true;
    },
    async insertComment(body) {
      const { data } = await this.$apollo.mutate({
        mutation: createNoteMutation,
        variables: {
          noteableId: convertToGraphQLId(TYPENAME_VULNERABILITY, this.vulnerabilityId),
          discussionId: convertToGraphQLId(TYPENAME_DISCUSSION, this.discussionId),
          body,
        },
      });

      const { errors } = data.createNote;

      if (errors?.length > 0) {
        throw errors;
      }
    },
    async updateComment(body) {
      const { data } = await this.$apollo.mutate({
        mutation: updateNoteMutation,
        variables: {
          id: convertToGraphQLId(TYPENAME_NOTE, this.comment.id),
          body,
        },
      });

      const { errors } = data.updateNote;

      if (errors?.length > 0) {
        throw errors;
      }
    },
    async saveComment(body) {
      this.isSavingComment = true;
      const isUpdatingComment = Boolean(this.comment);

      try {
        if (isUpdatingComment) {
          await this.updateComment(body);
        } else {
          await this.insertComment(body);
        }

        this.$emit('onCommentUpdated', () => {
          this.isSavingComment = false;
          this.cancelEditingComment();
        });
      } catch {
        this.isSavingComment = false;

        createAlert({
          message: s__(
            'VulnerabilityManagement|Something went wrong while trying to save the comment. Please try again later.',
          ),
        });
      }
    },
    async deleteComment() {
      this.isDeletingComment = true;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: destroyNoteMutation,
          variables: {
            id: convertToGraphQLId(TYPENAME_NOTE, this.comment.id),
          },
        });

        if (data.errors?.length > 0) {
          throw data.errors;
        }

        this.$emit('onCommentUpdated', () => {
          this.isDeletingComment = false;
        });
      } catch {
        this.isDeletingComment = false;

        createAlert({
          message: s__(
            'VulnerabilityManagement|Something went wrong while trying to delete the comment. Please try again later.',
          ),
        });
      }
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
      @focus="showCommentInput"
    >
      {{ s__('vulnerability|Add a comment') }}
    </button>
  </div>
</template>
