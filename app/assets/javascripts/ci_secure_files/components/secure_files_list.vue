<script>
import { GlTable, GlButton, GlIcon } from '@gitlab/ui';
import Api from '~/api';
import { s__, __ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  props: {
    projectId: {
      type: String,
      required: true,
    },
  }, 
  data() {
    return {
      projectSecureFiles: [],
    };
  }, 
  fields: [
    {
      key: 'name',
      label: s__('ciSecureFiles|Filename'),
    },
    {
      key: 'permissions',
      label: s__('ciSecureFiles|Permissions'),
      tdClass: 'text-plain',
    },
    {
      key: 'created_at',
      label: s__('ciSecureFiles|Created'),
    },
  ],
  components: {
    GlTable,
    GlButton,
    GlIcon,
    TimeagoTooltip,
  },
  computed: {
    fields() {
      return this.$options.fields;
    },
  },
  created() {
    this.getProjectSecureFiles();
  },
  methods: {
    async getProjectSecureFiles(){
      const response = await Api.projectSecureFiles(this.projectId)
      this.projectSecureFiles = response.data
    }
  }
};
</script>

<template>
  <div>

    <h2 data-testid="title" class="gl-font-size-h1 gl-mt-3 gl-mb-0">Secure Files</h2>

    <p>
      <span data-testid="info-message" class="gl-mr-2">
        Use Secure Files to store files used by your pipelines such as Android keystores, or Apple provisioning profiles and signing certificates. <a href="" rel="noopener" target="_blank" class="gl-link">More information</a>
      </span>
    </p>

    <gl-table
      :fields="fields"
      :items="this.projectSecureFiles"
      tbody-tr-class="js-ci-secure-files-row"
      data-qa-selector="ci_secure_files_table_content"
      sort-by="key"
      sort-direction="asc"
      stacked="lg"
      table-class="text-secondary"
      show-empty
      sort-icon-left
      no-sort-reset
    >
      <template #cell(name)="{ item }">
        {{item.name}}
      </template>

      <template #cell(permissions)="{ item }">
        {{item.permissions}}
      </template>

      <template #cell(created_at)="{ item }">
        <timeago-tooltip :time="item.created_at" />
      </template>

    </gl-table>
  </div>
</template>
