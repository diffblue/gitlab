<script>
import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { __ } from '~/locale';
import { DRAWER_AVATAR_SIZE } from '../../../constants';
import DrawerSectionHeader from '../shared/drawer_section_header.vue';
import FrameworkBadge from '../../shared/framework_badge.vue';

export default {
  components: {
    DrawerSectionHeader,
    FrameworkBadge,
    GlAvatarLabeled,
    GlAvatarLink,
  },
  props: {
    avatarUrl: {
      type: String,
      required: false,
      default: '',
    },
    complianceFramework: {
      type: Object,
      required: false,
      default: null,
    },
    name: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasComplianceFramework() {
      return !isEmpty(this.complianceFramework);
    },
  },
  i18n: {
    header: __('Project'),
  },
  DRAWER_AVATAR_SIZE,
};
</script>
<template>
  <div>
    <drawer-section-header>{{ $options.i18n.header }}</drawer-section-header>
    <div class="gl-display-flex gl-align-items-center">
      <gl-avatar-link :title="name" :href="url">
        <gl-avatar-labeled
          :size="$options.DRAWER_AVATAR_SIZE"
          :entity-name="name"
          label=""
          :sub-label="name"
          :src="avatarUrl"
        />
      </gl-avatar-link>
      <framework-badge
        v-if="hasComplianceFramework"
        :framework="complianceFramework"
        :show-default="false"
        size="sm"
        class="gl-ml-3"
      />
    </div>
  </div>
</template>
