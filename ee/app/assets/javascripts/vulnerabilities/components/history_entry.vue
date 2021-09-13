<script>
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import HistoryComment from './history_comment.vue';

export default {
  components: {
    EventItem,
    HistoryComment,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    notes() {
      return this.discussion.notes;
    },
    systemNote() {
      return this.notes.find((x) => x.system === true);
    },
    comments() {
      return this.notes.filter((x) => x !== this.systemNote);
    },
  },
};
</script>

<template>
  <div v-if="systemNote" class="card border-bottom system-note p-0">
    <event-item
      :id="systemNote.id"
      :author="systemNote.author"
      :created-at="systemNote.updatedAt"
      :icon-name="systemNote.systemNoteIconName"
      icon-class="timeline-icon m-0"
      class="m-3"
    >
      <template #header-message>{{ systemNote.body }}</template>
    </event-item>
    <hr v-if="comments.length" class="gl-m-0" />
    <history-comment
      v-for="comment in comments"
      ref="existingComment"
      :key="comment.id"
      :comment="comment"
      :discussion-id="discussion.replyId"
      v-on="$listeners"
    />
    <history-comment
      v-if="!comments.length"
      ref="newComment"
      :discussion-id="discussion.replyId"
      v-on="$listeners"
    />
  </div>
</template>
