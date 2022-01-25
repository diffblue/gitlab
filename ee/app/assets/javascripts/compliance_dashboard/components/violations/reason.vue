<script>
import { MERGE_REQUEST_VIOLATION_REASONS, MERGE_REQUEST_VIOLATION_MESSAGES } from '../../constants';
import UserAvatar from '../shared/user_avatar.vue';

export default {
  components: {
    UserAvatar,
  },
  props: {
    reason: {
      type: Number,
      required: true,
    },
    user: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    violation() {
      return MERGE_REQUEST_VIOLATION_REASONS[this.reason];
    },
    violationMessage() {
      return MERGE_REQUEST_VIOLATION_MESSAGES[this.violation];
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-flex gl-align-items-center">
    <span class="gl-mr-2">{{ violationMessage }}</span>
    <user-avatar v-if="user" :user="user" />
  </div>
</template>
