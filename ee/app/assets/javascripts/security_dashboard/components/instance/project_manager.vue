<script>
import { GlButton } from '@gitlab/ui';
import produce from 'immer';
import addProjectToSecurityDashboard from 'ee/security_dashboard/graphql/mutations/add_project_to_security_dashboard.mutation.graphql';
import deleteProjectFromSecurityDashboard from 'ee/security_dashboard/graphql/mutations/delete_project_from_security_dashboard.mutation.graphql';
import getProjects from 'ee/security_dashboard/graphql/queries/get_projects.query.graphql';
import instanceProjectsQuery from 'ee/security_dashboard/graphql/queries/instance_projects.query.graphql';
import { createInvalidProjectMessage } from 'ee/security_dashboard/utils/project_manager_utils';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';
import ProjectList from './project_list.vue';

export default {
  MINIMUM_QUERY_LENGTH: 3,
  PROJECTS_PER_PAGE: 20,
  components: {
    GlButton,
    ProjectList,
    ProjectSelector,
  },
  props: {
    isAuditor: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      searchQuery: '',
      projectSearchResults: [],
      selectedProjects: [],
      messages: {
        noResults: false,
        searchError: false,
        minimumQuery: false,
      },
      searchCount: 0,
      pageInfo: {
        endCursor: '',
        hasNextPage: true,
      },
    };
  },
  computed: {
    canAddProjects() {
      return this.selectedProjects.length > 0;
    },
    isSearchingProjects() {
      return this.searchCount > 0;
    },
  },
  methods: {
    toggleSelectedProject(project) {
      const isProjectSelected = this.selectedProjects.some(({ id }) => id === project.id);

      if (isProjectSelected) {
        this.selectedProjects = this.selectedProjects.filter((p) => p.id !== project.id);
      } else {
        this.selectedProjects.push(project);
      }
    },
    addProjects() {
      this.$emit('handleProjectManipulation', true);

      const addProjectsPromises = this.selectedProjects.map((project) => {
        return this.$apollo
          .mutate({
            mutation: addProjectToSecurityDashboard,
            variables: { id: project.id },
            update(store, { data: results }) {
              if (!results.addProjectToSecurityDashboard.project) {
                return;
              }

              const sourceData = store.readQuery({ query: instanceProjectsQuery });
              const newProject = results.addProjectToSecurityDashboard.project;

              const data = produce(sourceData, (draftData) => {
                draftData.instance.projects.edges = [
                  ...draftData.instance.projects.edges,
                  { node: newProject },
                ];
              });

              store.writeQuery({ query: instanceProjectsQuery, data });
            },
          })
          .then(({ data }) => {
            return {
              error: data?.addProjectToSecurityDashboard?.errors?.[0],
              project: data?.addProjectToSecurityDashboard?.project ?? project,
            };
          })
          .catch(() => {
            return {
              error: s__(
                'SecurityReports|Project was not found or you do not have permission to add this project to Security Dashboards.',
              ),
              project,
            };
          });
      });

      return Promise.all(addProjectsPromises)
        .then((response) => {
          const invalidProjects = response.filter((value) => value.error);
          this.$emit('handleProjectManipulation', false);

          if (invalidProjects.length) {
            const invalidProjectsByErrorMessage = invalidProjects.reduce((acc, value) => {
              acc[value.error] = acc[value.error] ?? [];
              acc[value.error].push(value.project);

              return acc;
            }, {});

            const errorMessages = Object.entries(invalidProjectsByErrorMessage).map(
              ([errorMessage, projects]) => {
                const invalidProjectsMessage = createInvalidProjectMessage(projects);
                return sprintf(
                  s__('SecurityReports|Unable to add %{invalidProjectsMessage}: %{errorMessage}'),
                  {
                    invalidProjectsMessage,
                    errorMessage,
                  },
                );
              },
            );

            createAlert({
              message: errorMessages.join(' '),
            });
          }
        })
        .finally(() => {
          this.projectSearchResults = [];
          this.selectedProjects = [];
        });
    },
    removeProject(project) {
      const { id } = project;
      this.$emit('handleProjectManipulation', true);

      this.$apollo
        .mutate({
          mutation: deleteProjectFromSecurityDashboard,
          variables: { id },
          update(store) {
            const sourceData = store.readQuery({ query: instanceProjectsQuery });

            const data = produce(sourceData, (draftData) => {
              draftData.instance.projects.edges = draftData.instance.projects.edges.filter(
                (curr) => curr.node.id !== id,
              );
            });

            store.writeQuery({ query: instanceProjectsQuery, data });
          },
        })
        .then(() => {
          this.$emit('handleProjectManipulation', false);
        })
        .catch(() =>
          createAlert({
            message: __('Something went wrong, unable to delete project'),
          }),
        );
    },
    searched(query) {
      this.searchQuery = query;
      this.pageInfo = { endCursor: '', hasNextPage: true };
      this.messages.minimumQuery = false;
      this.searchCount += 1;
      this.fetchSearchResults(true);
    },
    fetchSearchResults(isFirstSearch) {
      if (!this.pageInfo.hasNextPage) {
        return Promise.resolve();
      }

      if (!this.searchQuery || this.searchQuery.length < this.$options.MINIMUM_QUERY_LENGTH) {
        return this.cancelSearch();
      }

      return this.searchProjects(this.searchQuery, this.pageInfo)
        .then((payload) => {
          const {
            data: {
              projects: { nodes, pageInfo },
            },
          } = payload;

          if (isFirstSearch) {
            this.projectSearchResults = nodes;
            this.updateMessagesData(this.projectSearchResults.length === 0, false, false);
            this.searchCount = Math.max(0, this.searchCount - 1);
          } else {
            this.projectSearchResults = this.projectSearchResults.concat(nodes);
          }
          this.pageInfo = pageInfo;
        })
        .catch(this.fetchSearchResultsError);
    },
    cancelSearch() {
      this.projectSearchResults = [];
      this.pageInfo = {
        endCursor: '',
        hasNextPage: true,
      };
      this.updateMessagesData(false, false, true);
      this.searchCount = Math.max(0, this.searchCount - 1);
    },
    searchProjects(searchQuery, pageInfo) {
      return this.$apollo.query({
        query: getProjects,
        variables: {
          search: searchQuery,
          first: this.$options.PROJECTS_PER_PAGE,
          after: pageInfo.endCursor,
          searchNamespaces: true,
          sort: 'similarity',
          membership: !this.isAuditor,
        },
      });
    },
    fetchSearchResultsError() {
      this.projectSearchResults = [];
      this.updateMessagesData(false, true, false);
      this.searchCount = Math.max(0, this.searchCount - 1);
    },
    updateMessagesData(noResults, searchError, minimumQuery) {
      this.messages = {
        noResults,
        searchError,
        minimumQuery,
      };
    },
  },
};
</script>

<template>
  <section class="container">
    <div class="row justify-content-center mt-md-4">
      <div class="col col-lg-7">
        <h3 class="gl-font-lg gl-font-weight-bold gl-mt-0">
          {{ s__('SecurityReports|Monitored projects') }}
        </h3>
        <p class="gl-mb-4 gl-pb-3">
          {{
            s__(
              'SecurityReports|Add or remove projects to monitor in the security area. Projects included in this list will have their results displayed in the security dashboard and vulnerability report.',
            )
          }}
        </p>
        <div class="d-flex flex-column flex-md-row">
          <project-selector
            class="flex-grow mr-md-2"
            :project-search-results="projectSearchResults"
            :selected-projects="selectedProjects"
            :show-no-results-message="messages.noResults"
            :show-loading-indicator="isSearchingProjects"
            :show-minimum-search-query-message="messages.minimumQuery"
            :show-search-error-message="messages.searchError"
            @searched="searched"
            @projectClicked="toggleSelectedProject"
            @bottomReached="fetchSearchResults"
          />
          <div class="mb-3">
            <gl-button
              :disabled="!canAddProjects"
              variant="confirm"
              category="primary"
              @click="addProjects"
            >
              {{ s__('SecurityReports|Add projects') }}
            </gl-button>
          </div>
        </div>
      </div>
    </div>
    <div class="row justify-content-center mt-md-3">
      <project-list class="col col-lg-7" @projectRemoved="removeProject" />
    </div>
  </section>
</template>
