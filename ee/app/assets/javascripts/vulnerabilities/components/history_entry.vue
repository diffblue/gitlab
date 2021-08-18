<script>
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import HistoryComment from './history_comment.vue';

export default {
  components: { EventItem, HistoryComment },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    notesUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      notes: this.discussion.notes,
    };
  },
  computed: {
    systemNote() {
      return this.notes.find((x) => x.system === true);
    },
    comments() {
      return this.notes.filter((x) => x !== this.systemNote);
    },
  },
  watch: {
    discussion(newDiscussion) {
      this.notes = newDiscussion.notes;
    },
  },
  methods: {
    addComment({ response }) {
      this.notes.push(convertObjectPropsToCamelCase(response));
    },
    updateComment({ response, comment }) {
      const index = this.notes.indexOf(comment);

      if (index > -1) {
        this.notes.splice(index, 1, { ...comment, ...convertObjectPropsToCamelCase(response) });
      }
    },
    removeComment(comment) {
      const index = this.notes.indexOf(comment);

      if (index > -1) {
        this.notes.splice(index, 1);
      }
    },
  },
};
</script>

<template>
  <li v-if="systemNote" class="card border-bottom system-note p-0">
    <event-item
      :id="systemNote.id"
      :author="systemNote.author"
      :created-at="systemNote.updatedAt"
      :icon-name="systemNote.systemNoteIconName"
      icon-class="timeline-icon m-0"
      class="m-3"
    >
      <template #header-message>{{ systemNote.note }}</template>
    </event-item>

    <template v-if="comments.length" ref="existingComments">
      <hr class="m-3" />
      <history-comment
        v-for="comment in comments"
        :key="comment.id"
        ref="existingComment"
        :comment="comment"
        :discussion-id="discussion.replyId"
        :notes-url="notesUrl"
        @onCommentUpdated="updateComment"
        @onCommentDeleted="removeComment"
      />
    </template>

    <history-comment
      v-else
      ref="newComment"
      :discussion-id="discussion.replyId"
      :notes-url="notesUrl"
      @onCommentAdded="addComment"
    />
  </li>
</template>
