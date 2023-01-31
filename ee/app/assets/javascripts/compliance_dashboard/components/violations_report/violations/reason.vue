<script>
import { MERGE_REQUEST_VIOLATION_MESSAGES } from '../../../constants';
import UserAvatar from '../shared/user_avatar.vue';

export default {
  components: {
    UserAvatar,
  },
  props: {
    reason: {
      type: String,
      required: true,
      validator: (reason) => Object.keys(MERGE_REQUEST_VIOLATION_MESSAGES).includes(reason),
    },
    user: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    violationMessage() {
      return MERGE_REQUEST_VIOLATION_MESSAGES[this.reason];
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
