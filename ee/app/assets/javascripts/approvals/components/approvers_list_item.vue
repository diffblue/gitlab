<script>
import { GlButton, GlTooltipDirective, GlAvatarLabeled } from '@gitlab/ui';
import { __ } from '~/locale';
import { AVATAR_SHAPE_OPTION_CIRCLE, AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { TYPE_USER, TYPE_GROUP, TYPE_HIDDEN_GROUPS } from '../constants';
import HiddenGroupsItem from './hidden_groups_item.vue';

const VALID_APPROVER_TYPES = [TYPE_USER, TYPE_GROUP, TYPE_HIDDEN_GROUPS];

export default {
  components: {
    GlButton,
    GlAvatarLabeled,
    HiddenGroupsItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    approver: {
      type: Object,
      required: true,
      validator: ({ type }) => type && VALID_APPROVER_TYPES.includes(type),
    },
  },
  computed: {
    isGroup() {
      return this.approver.type === TYPE_GROUP;
    },
    isHiddenGroups() {
      return this.approver.type === TYPE_HIDDEN_GROUPS;
    },
    displayName() {
      return this.isGroup ? this.approver.full_path : this.approver.name;
    },
    avatarShape() {
      return this.isGroup ? AVATAR_SHAPE_OPTION_RECT : AVATAR_SHAPE_OPTION_CIRCLE;
    },
  },
  i18n: {
    removeApproverText: __('Remove'),
  },
};
</script>

<template>
  <transition name="fade">
    <li class="gl-display-flex! gl-align-items-center gl-px-5!">
      <hidden-groups-item v-if="isHiddenGroups" />
      <gl-avatar-labeled
        v-else
        :shape="avatarShape"
        :entity-name="approver.name"
        :label="displayName"
        :src="approver.avatar_url"
        :alt="approver.name"
        :size="24"
      />

      <gl-button
        v-gl-tooltip
        class="gl-ml-auto"
        icon="remove"
        :aria-label="$options.i18n.removeApproverText"
        :title="$options.i18n.removeApproverText"
        @click="$emit('remove', approver)"
      />
    </li>
  </transition>
</template>
