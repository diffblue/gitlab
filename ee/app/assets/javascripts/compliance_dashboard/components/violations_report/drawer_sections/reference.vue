<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import DrawerSectionHeader from '../shared/drawer_section_header.vue';

export default {
  components: {
    DrawerSectionHeader,
    GlLink,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    reference: {
      type: String,
      required: true,
    },
  },
  i18n: {
    header: __('Merge request'),
  },
};
</script>
<template>
  <div>
    <drawer-section-header>{{ $options.i18n.header }}</drawer-section-header>
    <gl-link :href="path">{{ reference }}</gl-link>
  </div>
</template>
