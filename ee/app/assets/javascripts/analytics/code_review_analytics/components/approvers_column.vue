<script>
import { GlAvatarLink, GlAvatar, GlAvatarsInline, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';

export const MAX_VISIBLE_AVATARS_DEFAULT = 3;
export const MAX_VISIBLE_AVATARS_COLLAPSED = 2;

export default {
  name: 'ApproversColumn',
  components: {
    GlAvatarLink,
    GlAvatar,
    GlAvatarsInline,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    approvers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    maxVisible() {
      return this.approvers.length > MAX_VISIBLE_AVATARS_DEFAULT
        ? MAX_VISIBLE_AVATARS_COLLAPSED
        : MAX_VISIBLE_AVATARS_DEFAULT;
    },
    hasMultipleApprovers() {
      return this.approvers.length > 1;
    },
    hasSingleApprover() {
      return this.approvers.length === 1;
    },
    firstApprover() {
      return this.approvers[0];
    },
    approversBadgeSrOnlyText() {
      return n__(
        '%d additional approver',
        '%d additional approvers',
        this.approvers.length - this.maxVisible,
      );
    },
  },
  avatarSize: 24,
  badgeTooltipMaxChars: 50,
};
</script>

<template>
  <div>
    <gl-avatars-inline
      v-if="hasMultipleApprovers"
      collapsed
      :avatars="approvers"
      :max-visible="maxVisible"
      :avatar-size="$options.avatarSize"
      badge-tooltip-prop="name"
      :badge-tooltip-max-chars="$options.badgeTooltipMaxChars"
      :badge-sr-only-text="approversBadgeSrOnlyText"
    >
      <template #avatar="{ avatar }">
        <gl-avatar-link v-gl-tooltip target="_blank" :href="avatar.web_url" :title="avatar.name">
          <gl-avatar :src="avatar.avatar_url" :size="$options.avatarSize" />
        </gl-avatar-link>
      </template>
    </gl-avatars-inline>
    <gl-avatar-link
      v-else-if="hasSingleApprover"
      v-gl-tooltip
      target="_blank"
      :href="firstApprover.web_url"
      :title="firstApprover.name"
    >
      <gl-avatar :src="firstApprover.avatar_url" :size="$options.avatarSize" />
    </gl-avatar-link>
    <template v-else> &ndash; </template>
  </div>
</template>
