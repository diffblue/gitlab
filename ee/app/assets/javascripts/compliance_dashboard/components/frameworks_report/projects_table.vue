<script>
import { GlFormCheckbox, GlLink, GlLoadingIcon, GlTable } from '@gitlab/ui';

import { __, s__ } from '~/locale';

import FrameworkBadge from '../shared/framework_badge.vue';
import SelectionOperations from './selection_operations.vue';

export default {
  name: 'ProjectsTable',
  components: {
    FrameworkBadge,
    SelectionOperations,

    GlFormCheckbox,
    GlLink,
    GlLoadingIcon,
    GlTable,
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
    groupPath: {
      type: String,
      required: true,
    },
    newGroupComplianceFrameworkPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedRows: [],
    };
  },
  computed: {
    hasProjects() {
      return this.projects.length > 0;
    },

    hasSelectedProjects() {
      return this.selectedRows.length > 0;
    },

    hasSelectedAllProjects() {
      return this.selectedRows.length === this.projects.length;
    },

    emptyStateIsVisible() {
      return !this.isLoading && !this.hasProjects;
    },
  },
  methods: {
    updateSelectedRows(selection) {
      this.selectedRows = selection;
    },
  },
  fields: [
    {
      key: 'selected',
      sortable: false,
      thClass: 'gl-vertical-align-middle!',
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'projectName',
      label: __('Project name'),
      thClass: 'gl-vertical-align-middle!',
      tdClass: 'gl-vertical-align-middle!',
      sortable: false,
    },
    {
      key: 'projectPath',
      label: __('Project path'),
      thClass: 'gl-vertical-align-middle!',
      tdAttr: { 'data-qa-selector': 'project_path_content' },
      tdClass: 'gl-vertical-align-middle!',
      sortable: false,
    },
    {
      key: 'complianceFramework',
      label: __('Compliance framework'),
      thClass: 'gl-vertical-align-middle!',
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
    <selection-operations
      :selection="selectedRows"
      :group-path="groupPath"
      :new-group-compliance-framework-path="newGroupComplianceFrameworkPath"
    />
    <gl-table
      :fields="$options.fields"
      :busy="isLoading"
      :items="projects"
      no-local-sorting
      show-empty
      stacked="lg"
      hover
<<<<<<< HEAD
      :tbody-tr-attr="qaRowAttributes"
=======
      selectable
      select-mode="multi"
      selected-variant="primary"
      @row-selected="updateSelectedRows"
>>>>>>> 6922789eb50e (Implement bulk applying compliance framework)
    >
      <template #head(selected)="{ selectAllRows, clearSelected }">
        <gl-form-checkbox
          class="gl-pt-2"
          :checked="hasSelectedProjects"
          :indeterminate="hasSelectedProjects && !hasSelectedAllProjects"
          @change="hasSelectedProjects ? clearSelected() : selectAllRows()"
        />
      </template>
      <template #cell(selected)="{ rowSelected, selectRow, unselectRow }">
        <div>
          <gl-form-checkbox
            class="gl-pt-2"
            :checked="rowSelected"
            @change="rowSelected ? unselectRow() : selectRow()"
          />
        </div>
      </template>
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
      <template #empty>
        <gl-loading-icon v-if="isLoading" size="lg" color="dark" class="gl-my-5" />
        <div
          v-else-if="emptyStateIsVisible"
          class="gl-my-5 gl-text-center"
          data-testid="projects-table-empty-state"
        >
          {{ $options.i18n.noProjectsFound }}
        </div>
      </template>
    </gl-table>
  </div>
</template>
