<script>
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { DRAWER_AVATAR_SIZE } from '../../constants';

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
  <gl-avatar-link
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
