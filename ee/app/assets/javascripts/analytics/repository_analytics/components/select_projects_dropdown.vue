<script>
import {
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlIntersectionObserver,
  GlLoadingIcon,
  GlModalDirective,
  GlSearchBoxByType,
} from '@gitlab/ui';
import produce from 'immer';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, n__ } from '~/locale';
import getGroupProjects from '../graphql/queries/get_group_projects.query.graphql';

export default {
  name: 'SelectProjectsDropdown',
  components: {
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlIntersectionObserver,
    GlLoadingIcon,
    GlSearchBoxByType,
  },
  directives: {
    GlModalDirective,
  },
  inject: {
    groupFullPath: {
      default: '',
    },
  },
  apollo: {
    groupProjects: {
      query: getGroupProjects,
      variables() {
        return {
          groupFullPath: this.groupFullPath,
        };
      },
      update(data) {
        return (
          data.group?.projects?.nodes?.map((project) => ({
            ...project,
            parsedId: getIdFromGraphQLId(project.id),
            isSelected: false,
          })) || []
        );
      },
      result({ data }) {
        this.projectsPageInfo = data?.group?.projects?.pageInfo || {};
      },
      error() {
        this.handleError();
      },
    },
  },
  data() {
    return {
      groupProjects: [],
      projectsPageInfo: {},
      projectSearchTerm: '',
      selectAllProjects: true,
    };
  },
  computed: {
    filteredProjects() {
      return this.groupProjects.filter((project) =>
        project.name.toLowerCase().includes(this.projectSearchTerm.toLowerCase()),
      );
    },
    dropdownPlaceholder() {
      if (this.selectAllProjects) {
        return __('All projects selected');
      }
      if (this.selectedProjectIds.length) {
        return n__('%d project selected', '%d projects selected', this.selectedProjectIds.length);
      }
      return __('Select projects');
    },
    selectedProjectIds() {
      return this.groupProjects
        .filter((project) => project.isSelected)
        .map((project) => project.id);
    },
  },
  methods: {
    clickDropdownProject(id) {
      const index = this.groupProjects.map((project) => project.id).indexOf(id);
      this.groupProjects[index].isSelected = !this.groupProjects[index].isSelected;
      this.selectAllProjects = false;
      this.$emit('select-project', this.groupProjects[index]);
    },
    clickSelectAllProjects() {
      this.selectAllProjects = true;
      this.groupProjects = this.groupProjects.map((project) => ({
        ...project,
        isSelected: false,
      }));
      this.$emit('select-all-projects', this.groupProjects);
    },
    handleError() {
      this.$emit('projects-query-error');
    },
    loadMoreProjects() {
      this.$apollo.queries.groupProjects
        .fetchMore({
          variables: {
            groupFullPath: this.groupFullPath,
            after: this.projectsPageInfo.endCursor,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            const results = produce(fetchMoreResult, (draftData) => {
              draftData.group.projects.nodes = [
                ...previousResult.group.projects.nodes,
                ...draftData.group.projects.nodes,
              ];
            });
            return results;
          },
        })
        .catch(() => {
          this.handleError();
        });
    },
  },
  text: {
    projectDropdownHeader: __('Projects'),
    projectDropdownAllProjects: __('All projects'),
  },
};
</script>

<template>
  <gl-dropdown right :text="dropdownPlaceholder" data-testid="select-projects-dropdown">
    <gl-dropdown-section-header>
      {{ $options.text.projectDropdownHeader }}
    </gl-dropdown-section-header>
    <gl-search-box-by-type v-model.trim="projectSearchTerm" />
    <gl-dropdown-item
      is-check-item
      :is-checked="selectAllProjects"
      data-testid="select-all-projects"
      @click.native.capture.stop="clickSelectAllProjects()"
      >{{ $options.text.projectDropdownAllProjects }}</gl-dropdown-item
    >
    <gl-dropdown-item
      v-for="project in filteredProjects"
      :key="project.id"
      is-check-item
      :is-checked="project.isSelected"
      :data-testid="`select-project-${project.id}`"
      @click.native.capture.stop="clickDropdownProject(project.id)"
      >{{ project.name }}</gl-dropdown-item
    >
    <gl-intersection-observer v-if="projectsPageInfo.hasNextPage" @appear="loadMoreProjects">
      <gl-loading-icon v-if="$apollo.queries.groupProjects.loading" size="lg" />
    </gl-intersection-observer>
  </gl-dropdown>
</template>
