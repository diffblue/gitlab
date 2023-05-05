<script>
import { GlTable, GlLoadingIcon, GlButton } from '@gitlab/ui';

/* eslint-disable @gitlab/require-i18n-strings */
// I opted to disable the rule for this file to not add more changes, I will delete the rule exclusion and the placeholder strings once the component grows more.
const i18n = {
  placeholderButtonText: 'click me to toggle loading',
  placeholderText: 'Exclusion form placeholder',
};

export default {
  components: {
    GlTable,
    GlLoadingIcon,
    GlButton,
  },
  i18n,
  data() {
    return {
      loading: false,
      tableItems: [
        {
          namespace_id: 1,
          name: 2,
          reason: 3,
          operations: 4,
        },
      ],
    };
  },
  methods: {
    handleExcludingNamespace() {
      this.loading = true;
    },
  },
};
</script>

<template>
  <div>
    <p class="gl-text-secondary">
      {{
        s__(
          "NamespaceLimits|These namespaces won't receive any notifications nor any degraded functionality while they remain on this list",
        )
      }}
    </p>

    <gl-table :items="tableItems" :busy="loading">
      <template #table-busy>
        <div class="gl-text-center gl-text-red-500 gl-my-2">
          <gl-loading-icon />
        </div>
      </template>
    </gl-table>
    <br />
    <p>
      {{ $options.i18n.placeholderText }}
      <gl-button @click="handleExcludingNamespace">
        {{ $options.i18n.placeholderButtonText }}
      </gl-button>
    </p>
  </div>
</template>
