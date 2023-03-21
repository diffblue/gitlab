<script>
import { GlLink, GlLoadingIcon, GlTableLite } from '@gitlab/ui';

import { __, s__ } from '~/locale';

import FrameworkBadge from '../shared/framework_badge.vue';

export default {
  name: 'ProjectsTable',
  components: {
    FrameworkBadge,
    GlLink,
    GlLoadingIcon,
    GlTableLite,
  },
  props: {
    projects: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    emptyStateIsVisible() {
      return !this.isLoading && !this.projects.length;
    },
  },
  fields: [
    {
      key: 'projectName',
      label: __('Project name'),
      tdClass: 'gl-vertical-align-middle!',
      sortable: false,
    },
    {
      key: 'projectPath',
      label: __('Project path'),
      tdAttr: { 'data-qa-selector': 'project_path_content' },
      tdClass: 'gl-vertical-align-middle!',
      sortable: false,
    },
    {
      key: 'complianceFramework',
      label: __('Compliance framework'),
      tdClass: 'gl-vertical-align-middle!',
      sortable: false,
    },
  ],
  i18n: {
    noProjectsFound: s__('ComplianceReport|No projects found'),
    noFrameworkMessage: s__('ComplianceReport|No framework'),
  },
  methods: {
    qaRowAttributes(project, type) {
      if (type === 'row') {
        return {
          'data-qa-selector': 'project_frameworks_row',
          'data-qa-project-name': project.name,
        };
      }

      return {};
    },
  },
};
</script>
<template>
  <div>
    <gl-table-lite
      :fields="$options.fields"
      :items="projects"
      :empty-text="$options.i18n.noProjectsFound"
      no-local-sorting
      show-empty
      stacked="lg"
      hover
      :tbody-tr-attr="qaRowAttributes"
    >
      <template #cell(projectName)="{ item }">
        <gl-link :href="item.webUrl" data-qa-selector="project_name_link">{{ item.name }} </gl-link>
      </template>
      <template #cell(projectPath)="{ item: { fullPath } }">
        {{ fullPath }}
      </template>
      <template #cell(complianceFramework)="{ item: { complianceFrameworks } }">
        <framework-badge
          v-for="framework in complianceFrameworks"
          :key="framework.id"
          :framework="framework"
        />
        <template v-if="!complianceFrameworks.length">{{
          $options.i18n.noFrameworkMessage
        }}</template>
      </template>
    </gl-table-lite>
    <gl-loading-icon v-if="isLoading" size="lg" color="dark" class="gl-my-5" />
    <div
      v-else-if="emptyStateIsVisible"
      class="gl-my-5 gl-text-center"
      data-testid="projects-table-empty-state"
    >
      {{ $options.i18n.noProjectsFound }}
    </div>
  </div>
</template>
