<script>
import {
  GlDashboardSkeleton,
  GlButton,
  GlEmptyState,
  GlLink,
  GlModal,
  GlModalDirective,
  GlSprintf,
} from '@gitlab/ui';
import VueDraggable from 'vuedraggable';
import { mapState, mapActions } from 'vuex';
import { s__, __ } from '~/locale';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import DashboardProject from './project.vue';

export default {
  informationText: s__(
    'OperationsDashboard|The Operations and Environments dashboards share the same list of projects. When you add or remove a project from one, GitLab adds or removes the project from the other. %{linkStart}More information%{linkEnd}',
  ),
  components: {
    DashboardProject,
    GlDashboardSkeleton,
    GlButton,
    GlEmptyState,
    GlLink,
    GlModal,
    GlSprintf,
    ProjectSelector,
    VueDraggable,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    addPath: {
      type: String,
      required: true,
    },
    listPath: {
      type: String,
      required: true,
    },
    emptyDashboardSvgPath: {
      type: String,
      required: true,
    },
    emptyDashboardHelpPath: {
      type: String,
      required: true,
    },
    operationsDashboardHelpPath: {
      type: String,
      required: true,
    },
  },
  modalId: 'add-projects-modal',
  computed: {
    ...mapState([
      'isLoadingProjects',
      'selectedProjects',
      'projectSearchResults',
      'searchCount',
      'messages',
      'pageInfo',
    ]),
    projects: {
      get() {
        return this.$store.state.projects;
      },
      set(projects) {
        this.setProjects(projects);
      },
    },
    isSearchingProjects() {
      return this.searchCount > 0;
    },
    okDisabled() {
      return Object.keys(this.selectedProjects).length === 0;
    },
    actionPrimary() {
      return {
        text: s__('OperationsDashboard|Add projects'),
        attributes: {
          disabled: this.okDisabled,
          variant: 'confirm',
        },
      };
    },
  },
  created() {
    this.setProjectEndpoints({
      list: this.listPath,
      add: this.addPath,
    });
    this.fetchProjects();
  },
  methods: {
    ...mapActions([
      'fetchNextPage',
      'fetchSearchResults',
      'addProjectsToDashboard',
      'fetchProjects',
      'setProjectEndpoints',
      'clearSearchResults',
      'toggleSelectedProject',
      'setSearchQuery',
      'setProjects',
    ]),
    addProjects() {
      this.addProjectsToDashboard();
    },
    onCancel() {
      this.clearSearchResults();
    },
    onOk() {
      this.addProjectsToDashboard().then(this.clearSearchResults).catch(this.clearSearchResults);
    },
    searched(query) {
      this.setSearchQuery(query);
      this.fetchSearchResults();
    },
    projectClicked(project) {
      this.toggleSelectedProject(project);
    },
  },
  modal: {
    actionCancel: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <div class="operations-dashboard">
    <gl-modal
      :modal-id="$options.modalId"
      :title="s__('OperationsDashboard|Add projects')"
      :action-primary="actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      data-qa-selector="add_projects_modal"
      @canceled="onCancel"
      @primary="onOk"
    >
      <project-selector
        ref="projectSelector"
        :project-search-results="projectSearchResults"
        :selected-projects="selectedProjects"
        :show-no-results-message="messages.noResults"
        :show-loading-indicator="isSearchingProjects"
        :show-minimum-search-query-message="messages.minimumQuery"
        :show-search-error-message="messages.searchError"
        :total-results="pageInfo.totalResults"
        @searched="searched"
        @projectClicked="projectClicked"
        @bottomReached="fetchNextPage"
      />
    </gl-modal>

    <div class="page-title-holder flex-fill d-flex align-items-center">
      <h1 class="js-dashboard-title page-title gl-font-size-h-display text-nowrap flex-fill">
        {{ s__('OperationsDashboard|Operations Dashboard') }}
      </h1>
      <gl-button
        v-if="projects.length"
        v-gl-modal="$options.modalId"
        variant="confirm"
        category="primary"
        data-testid="add-projects-button"
        data-qa-selector="add_projects_button"
      >
        {{ s__('OperationsDashboard|Add projects') }}
      </gl-button>
    </div>
    <p class="gl-mt-2 gl-mb-4">
      <gl-sprintf :message="$options.informationText">
        <template #link="{ content }">
          <gl-link :href="operationsDashboardHelpPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <div class="gl-mt-3">
      <vue-draggable
        v-if="projects.length"
        v-model="projects"
        group="dashboard-projects"
        class="row gl-mt-3 dashboard-cards"
      >
        <div v-for="project in projects" :key="project.id" class="col-12 col-md-6 col-xl-4 px-2">
          <dashboard-project :project="project" />
        </div>
      </vue-draggable>

      <gl-dashboard-skeleton v-else-if="isLoadingProjects" />

      <gl-empty-state
        v-else
        :title="s__(`OperationsDashboard|Add a project to the dashboard`)"
        :svg-path="emptyDashboardSvgPath"
      >
        <template #description>
          {{
            s__(
              `OperationsDashboard|The operations dashboard provides a summary of each project's operational health, including pipeline and alert statuses.`,
            )
          }}
          <gl-link :href="emptyDashboardHelpPath" data-testid="documentation-link">{{
            s__('OperationsDashboard|More information')
          }}</gl-link
          >.
        </template>
        <template #actions>
          <gl-button
            v-gl-modal="$options.modalId"
            variant="confirm"
            data-testid="add-projects-button"
            data-qa-selector="add_projects_button"
          >
            {{ s__('OperationsDashboard|Add projects') }}
          </gl-button>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
