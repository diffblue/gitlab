<script>
import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { __ } from '~/locale';
import { DRAWER_AVATAR_SIZE } from '../../constants';
import DrawerSectionHeader from '../shared/drawer_section_header.vue';
import DrawerSectionSubHeader from '../shared/drawer_section_sub_header.vue';

export default {
  components: {
    DrawerSectionHeader,
    DrawerSectionSubHeader,
    GlAvatarLabeled,
    GlAvatarLink,
  },
  props: {
    mergedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    hasMergedBy() {
      return Boolean(this.mergedBy?.name);
    },
  },
  i18n: {
    header: __('Merged by'),
    emptyHeader: __('Unknown user'),
  },
  DRAWER_AVATAR_SIZE,
};
</script>
<template>
  <div>
    <drawer-section-header>{{ $options.i18n.header }}</drawer-section-header>
    <gl-avatar-link
      v-if="hasMergedBy"
      :title="mergedBy.name"
      :href="mergedBy.web_url"
      class="js-user-link"
      :data-user-id="mergedBy.id"
      :data-name="mergedBy.name"
    >
      <gl-avatar-labeled
        :size="$options.DRAWER_AVATAR_SIZE"
        :entity-name="mergedBy.name"
        label=""
        :sub-label="mergedBy.name"
        :src="mergedBy.avatar_url"
      />
    </gl-avatar-link>
    <drawer-section-sub-header v-else :is-empty="true">
      {{ $options.i18n.emptyHeader }}
    </drawer-section-sub-header>
  </div>
</template>
