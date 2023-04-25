<script>
import Vue from 'vue';
import { GlFormCheckbox, GlButton, GlLink, GlLoadingIcon, GlTable, GlToast } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';

import FrameworkBadge from '../shared/framework_badge.vue';
import setComplianceFrameworkMutation from '../../graphql/set_compliance_framework.mutation.graphql';
import SelectionOperations from './selection_operations.vue';
import FrameworkSelectionBox from './framework_selection_box.vue';

Vue.use(GlToast);

export default {
  name: 'ProjectsTable',
  components: {
    FrameworkBadge,
    FrameworkSelectionBox,
    SelectionOperations,

    GlButton,
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
    rootAncestorPath: {
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
      projectsPendindSingleOperation: [],
      isApplyInProgress: false,
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
  },
  methods: {
    updateSelectedRows(selection) {
      this.selectedRows = selection;
    },

    qaRowAttributes(project, type) {
      if (type === 'row') {
        return {
          'data-qa-selector': 'project_frameworks_row',
          'data-qa-project-name': project.name,
        };
      }

      return {};
    },

    async applyOperations(operations) {
      const successMessage = operations.some((entry) => Boolean(entry.frameworkId))
        ? this.$options.i18n.successApplyToastMessage
        : this.$options.i18n.successRemoveToastMessage;

      try {
        this.isApplyInProgress = true;
        const results = await Promise.all(
          operations.map((entry) =>
            this.$apollo.mutate({
              mutation: setComplianceFrameworkMutation,
              variables: {
                projectId: entry.projectId,
                frameworkId: entry.frameworkId,
              },
            }),
          ),
        );

        const firstError = results.find(
          (response) => response.data.projectSetComplianceFramework.errors.length,
        );
        if (firstError) {
          throw firstError;
        }
        this.$toast.show(successMessage, {
          action: {
            text: __('Undo'),
            onClick: () => {
              this.applyOperations(
                operations.map((entry) => ({
                  projectId: entry.projectId,
                  previousFrameworkId: entry.frameworkId,
                  frameworkId: entry.previousFrameworkId,
                })),
              );
            },
          },
        });
      } catch (e) {
        createAlert({
          message: __('Something went wrong on our end.'),
        });
      } finally {
        this.isApplyInProgress = false;
        this.$emit('update');
      }
    },

    async applySingleItemOperation(operation) {
      try {
        this.projectsPendindSingleOperation.push(operation.projectId);
        await this.applyOperations([operation]);
      } finally {
        this.projectsPendindSingleOperation = this.projectsPendindSingleOperation.filter(
          (projectId) => projectId !== operation.projectId,
        );
      }
    },

    hasPendingSingleOperation(projectId) {
      return this.projectsPendindSingleOperation.indexOf(projectId) > -1;
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
    addFrameworkMessage: s__('ComplianceReport|Add framework'),

    successApplyToastMessage: s__('ComplianceReport|Framework successfully applied'),
    successRemoveToastMessage: s__('ComplianceReport|Framework successfully removed'),
  },
};
</script>
<template>
  <div>
    <selection-operations
      :selection="selectedRows"
      :root-ancestor-path="rootAncestorPath"
      :new-group-compliance-framework-path="newGroupComplianceFrameworkPath"
      :is-apply-in-progress="isApplyInProgress"
      @change="applyOperations"
    />
    <gl-table
      :fields="$options.fields"
      :busy="isLoading"
      :items="projects"
      no-local-sorting
      show-empty
      stacked="lg"
      hover
      :tbody-tr-attr="qaRowAttributes"
      selectable
      select-mode="multi"
      selected-variant="primary"
      @row-selected="updateSelectedRows"
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
      <template #cell(complianceFramework)="{ item: { id, complianceFrameworks } }">
        <gl-loading-icon v-if="hasPendingSingleOperation(id)" size="sm" inline />
        <framework-selection-box
          v-else-if="!complianceFrameworks.length"
          :new-group-compliance-framework-path="newGroupComplianceFrameworkPath"
          :root-ancestor-path="rootAncestorPath"
          @select="
            applySingleItemOperation({
              projectId: id,
              frameworkId: $event,
              previousFrameworkId: null,
            })
          "
        >
          <template #toggle>
            <gl-button icon="plus" category="tertiary" variant="info">
              {{ $options.i18n.addFrameworkMessage }}
            </gl-button>
          </template>
        </framework-selection-box>
        <framework-badge
          v-for="framework in complianceFrameworks"
          v-else
          :key="framework.id"
          closeable
          :framework="framework"
          @close="
            applySingleItemOperation({
              projectId: id,
              frameworkId: null,
              previousFrameworkId: framework.id,
            })
          "
        />
      </template>
      <template #table-busy>
        <gl-loading-icon size="lg" color="dark" class="gl-my-5" />
      </template>
      <template #empty>
        <div class="gl-my-5 gl-text-center" data-testid="projects-table-empty-state">
          {{ $options.i18n.noProjectsFound }}
        </div>
      </template>
    </gl-table>
  </div>
</template>
