<script>
import {
  GlButton,
  GlDashboardSkeleton,
  GlEmptyState,
  GlLink,
  GlModal,
  GlModalDirective,
  GlPagination,
  GlSprintf,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import Environment from './environment.vue';
import ProjectHeader from './project_header.vue';

export default {
  addProjectsModalHeader: s__('EnvironmentsDashboard|Add projects'),
  addProjectsModalSubmit: s__('EnvironmentsDashboard|Add projects'),

  dashboardHeader: s__('EnvironmentsDashboard|Environments Dashboard'),

  addProjectsButton: s__('EnvironmentsDashboard|Add projects'),

  emptyDashboardHeader: s__('EnvironmentsDashboard|Add a project to the dashboard'),

  emptyDashboardDocs: s__(
    "EnvironmentsDashboard|The environments dashboard provides a summary of each project's environments' status, including pipeline and alert statuses.",
  ),

  viewDocumentationButton: __('View documentation'),
  informationText: s__(
    'EnvironmentsDashboard|This dashboard displays 3 environments per project, and is linked to the Operations Dashboard. When you add or remove a project from one dashboard, GitLab adds or removes the project from the other. %{linkStart}More information%{linkEnd}',
  ),

  components: {
    Environment,
    GlButton,
    GlDashboardSkeleton,
    GlEmptyState,
    GlLink,
    GlModal,
    GlPagination,
    GlSprintf,
    ProjectHeader,
    ProjectSelector,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  modalId: 'add-projects-modal',
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
    environmentsDashboardHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'projects',
      'projectTokens',
      'isLoadingProjects',
      'selectedProjects',
      'projectSearchResults',
      'searchCount',
      'searchQuery',
      'messages',
      'pageInfo',
      'projectsPage',
    ]),
    currentPage: {
      get() {
        return this.projectsPage.pageInfo.page;
      },
      set(newPage) {
        this.paginateDashboard(newPage);
      },
    },
    projectsPerPage() {
      return this.projectsPage.pageInfo.perPage;
    },
    totalProjects() {
      return this.projectsPage.pageInfo.total;
    },
    shouldPaginate() {
      return this.projectsPage.pageInfo.totalPages > 1;
    },
    isSearchingProjects() {
      return this.searchCount > 0;
    },
    okDisabled() {
      return isEmpty(this.selectedProjects);
    },
  },
  watch: {
    currentPage() {
      window.scrollTo(0, 0);
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
      'fetchSearchResults',
      'addProjectsToDashboard',
      'fetchProjects',
      'fetchNextPage',
      'setProjectEndpoints',
      'clearSearchResults',
      'toggleSelectedProject',
      'setSearchQuery',
      'removeProject',
      'clearProjectsEtagPoll',
      'stopProjectsPolling',
      'paginateDashboard',
    ]),
    addProjects() {
      this.addProjectsToDashboard();
    },
    onModalHidden() {
      this.clearSearchResults();
    },
    onOk() {
      this.addProjectsToDashboard();
    },
    searched(query) {
      this.setSearchQuery(query);
      this.fetchSearchResults();
    },
    projectClicked(project) {
      this.toggleSelectedProject(project);
    },
  },
};
</script>

<template>
  <div class="environments-dashboard">
    <gl-modal
      :modal-id="$options.modalId"
      :title="$options.addProjectsModalHeader"
      :ok-title="$options.addProjectsModalSubmit"
      :ok-disabled="okDisabled"
      @hidden="onModalHidden"
      @ok="onOk"
    >
      <p>
        <gl-sprintf :message="$options.informationText">
          <template #link="{ content }">
            <gl-link :href="environmentsDashboardHelpPath" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
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
        {{ $options.dashboardHeader }}
      </h1>
      <gl-button v-gl-modal="$options.modalId" class="js-add-projects-button" variant="confirm">
        {{ $options.addProjectsButton }}
      </gl-button>
    </div>
    <p class="mt-2 mb-4 js-page-limits-message">
      <gl-sprintf :message="$options.informationText">
        <template #link="{ content }">
          <gl-link :href="environmentsDashboardHelpPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <div class="gl-mt-3">
      <div v-if="projects.length">
        <div v-for="project in projects" :key="project.id">
          <project-header :project="project" @remove="removeProject" />
          <div class="row gl-mt-3 no-gutters mx-n2">
            <environment
              v-for="environment in project.environments"
              :key="environment.id"
              :environment="environment"
              class="col-12 col-md-6 col-xl-4 px-2"
            />
          </div>
        </div>

        <gl-pagination
          v-if="shouldPaginate"
          v-model="currentPage"
          :per-page="projectsPerPage"
          :total-items="totalProjects"
          align="center"
          class="gl-w-full gl-mt-3"
        />
      </div>

      <gl-dashboard-skeleton v-else-if="isLoadingProjects" />

      <gl-empty-state
        v-else
        :title="$options.emptyDashboardHeader"
        :svg-path="emptyDashboardSvgPath"
      >
        <template #description>
          {{ $options.emptyDashboardDocs }}
          <gl-link :href="emptyDashboardHelpPath" class="js-documentation-link">{{
            $options.viewDocumentationButton
          }}</gl-link
          >.
        </template>
        <template #actions>
          <gl-button v-gl-modal="$options.modalId" variant="confirm" class="js-add-projects-button">
            {{ s__('ModalButton|Add projects') }}
          </gl-button>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
