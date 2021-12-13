<script>
import { GlBadge, GlTabs, GlTab } from '@gitlab/ui';
import { settingsTabTitle, overridesTabTitle } from '~/integrations/constants';

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
      type: [Number, String],
      required: false,
      default: null,
    },
  },
  i18n: {
    settingsTabTitle,
    overridesTabTitle,
  },
};
</script>

<template>
  <gl-tabs>
    <template #tabs-start>
      <li class="nav-item" role="presentation">
        <a class="nav-link gl-tab-nav-item" :href="editPath">{{
          $options.i18n.settingsTabTitle
        }}</a>
      </li>
    </template>

    <gl-tab active>
      <template #title>
        {{ $options.i18n.overridesTabTitle }}
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
