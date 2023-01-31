<script>
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { DRAWER_AVATAR_SIZE } from '../../../constants';

export default {
  components: {
    GlAvatar,
    GlAvatarLink,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
  },
  DRAWER_AVATAR_SIZE,
};
</script>

<template>
  <!-- The key attribute is required so that the node updates when the user changes, which in turn updates the user popover event. -->
  <gl-avatar-link
    :key="user.id"
    target="blank"
    :href="user.webUrl"
    :title="user.name"
    class="js-user-link"
    :data-user-id="user.id"
    :data-name="user.name"
  >
    <gl-avatar :src="user.avatarUrl" :entity-name="user.name" :size="$options.DRAWER_AVATAR_SIZE" />
  </gl-avatar-link>
</template>
