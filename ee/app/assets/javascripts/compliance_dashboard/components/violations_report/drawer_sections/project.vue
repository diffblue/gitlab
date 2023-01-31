<script>
import { GlAvatarLabeled, GlAvatarLink, GlLabel } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { __ } from '~/locale';
import { DRAWER_AVATAR_SIZE } from '../../../constants';
import DrawerSectionHeader from '../shared/drawer_section_header.vue';

export default {
  components: {
    DrawerSectionHeader,
    GlAvatarLabeled,
    GlAvatarLink,
    GlLabel,
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
      <gl-label
        v-if="hasComplianceFramework"
        class="gl-ml-3"
        :title="complianceFramework.name"
        :background-color="complianceFramework.color"
        :description="complianceFramework.description"
        size="sm"
      />
    </div>
  </div>
</template>
