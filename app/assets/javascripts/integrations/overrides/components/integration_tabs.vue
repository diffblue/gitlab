<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlTabs,
    GlTab,
  },
  inject: {
    editPath: {
      default: '',
    },
  },
  props: {
    projectOverridesCount: {
      type: Number,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <gl-tabs>
    <template #tabs-start>
      <li class="nav-item" role="presentation">
        <a class="nav-link gl-tab-nav-item" :href="editPath">{{ __('Settings') }}</a>
      </li>
    </template>

    <gl-tab active>
      <template #title>
        {{ s__('Integrations|Projects using custom settings') }}
        <gl-badge
          v-if="projectOverridesCount !== null"
          variant="muted"
          size="sm"
          class="gl-tab-counter-badge"
          >{{ projectOverridesCount }}</gl-badge
        >
      </template>
    </gl-tab>
  </gl-tabs>
</template>
