<script>
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

export default {
  components: {
    UserAvatarList,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    users: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <span class="gl-font-sm gl-text-gray-500">{{ label }}</span>
    <user-avatar-list class="gl-ml-2" :items="users" :img-size="16" />
  </div>
</template>
