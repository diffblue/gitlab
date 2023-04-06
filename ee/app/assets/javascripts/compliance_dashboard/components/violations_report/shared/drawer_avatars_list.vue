<script>
import { GlAvatarsInline } from '@gitlab/ui';
import { DRAWER_AVATAR_SIZE, DRAWER_MAXIMUM_AVATARS } from '../../../constants';
import DrawerSectionSubHeader from './drawer_section_sub_header.vue';
import UserAvatar from './user_avatar.vue';

export default {
  components: {
    DrawerSectionSubHeader,
    GlAvatarsInline,
    UserAvatar,
  },
  props: {
    avatars: {
      type: Array,
      required: false,
      default: () => [],
    },
    header: {
      type: String,
      required: false,
      default: '',
    },
    emptyHeader: {
      type: String,
      required: false,
      default: '',
    },
    badgeSrOnlyText: {
      type: String,
      required: true,
    },
  },
  computed: {
    isEmpty() {
      return !this.avatars.length;
    },
    headerText() {
      if (this.isEmpty) {
        return this.emptyHeader;
      }

      return this.header;
    },
  },
  DRAWER_AVATAR_SIZE,
  DRAWER_MAXIMUM_AVATARS,
};
</script>
<template>
  <div>
    <drawer-section-sub-header v-if="headerText" :is-empty="isEmpty">
      {{ headerText }}
    </drawer-section-sub-header>
    <gl-avatars-inline
      v-if="!isEmpty"
      :avatars="avatars"
      :max-visible="$options.DRAWER_MAXIMUM_AVATARS"
      :avatar-size="$options.DRAWER_AVATAR_SIZE"
      :badge-sr-only-text="badgeSrOnlyText"
      class="gl-flex-wrap gl-w-full!"
      badge-tooltip-prop="name"
    >
      <template #avatar="{ avatar }">
        <user-avatar :user="avatar" />
      </template>
    </gl-avatars-inline>
  </div>
</template>
