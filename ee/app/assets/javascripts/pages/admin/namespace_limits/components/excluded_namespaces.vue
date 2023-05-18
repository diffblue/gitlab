<script>
import { GlTable, GlLoadingIcon } from '@gitlab/ui';
import ExcludedNamespacesForm from './excluded_namespaces_form.vue';

export default {
  components: {
    GlTable,
    GlLoadingIcon,
    ExcludedNamespacesForm,
  },
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
    <excluded-namespaces-form @added="handleExcludingNamespace" />
  </div>
</template>
