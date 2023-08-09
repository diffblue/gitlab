<script>
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import GroupsDropdownFilter from '../../shared/components/groups_dropdown_filter.vue';
import { accessLevelReporter, projectsPerPage } from '../constants';

export default {
  components: {
    GroupsDropdownFilter,
    ProjectsDropdownFilter,
  },
  props: {
    group: {
      type: Object,
      required: false,
      default: null,
    },
    project: {
      type: Object,
      required: false,
      default: null,
    },
    hideGroupDropDown: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      groupId: this.group && this.group.id ? this.group.id : null,
    };
  },
  computed: {
    ...mapState('filters', ['groupNamespace']),
    showProjectsDropdownFilter() {
      return Boolean(this.groupId);
    },
    projects() {
      return this.project && Object.keys(this.project).length ? [this.project] : null;
    },
    projectsQueryParams() {
      return {
        first: projectsPerPage,
        includeSubgroups: true,
      };
    },
  },
  methods: {
    ...mapActions('filters', ['setGroupNamespace', 'setProjectPath']),
    onGroupSelected({ id, full_path: fullPath }) {
      this.groupId = id;
      this.setGroupNamespace(fullPath);
      this.$emit('groupSelected', { groupId: id, groupNamespace: fullPath });
    },
    onProjectsSelected(selectedProjects) {
      const projectNamespace = selectedProjects[0]?.fullPath || null;
      const projectId = selectedProjects[0]?.id || null;

      this.setProjectPath(projectNamespace);
      this.$emit('projectSelected', {
        groupNamespace: this.groupNamespace,
        groupId: this.groupId,
        projectNamespace,
        projectId,
      });
    },
  },
  groupsQueryParams: {
    min_access_level: accessLevelReporter,
  },
};
</script>

<template>
  <div class="dropdown-container d-flex flex-column flex-lg-row">
    <groups-dropdown-filter
      v-if="!hideGroupDropDown"
      class="group-select"
      :query-params="$options.groupsQueryParams"
      :default-group="group"
      @selected="onGroupSelected"
    />
    <projects-dropdown-filter
      v-if="showProjectsDropdownFilter"
      :key="groupId"
      class="project-select"
      toggle-classes="gl-max-w-26"
      :default-projects="projects"
      :query-params="projectsQueryParams"
      :group-id="groupId"
      :group-namespace="groupNamespace"
      :use-graphql="true"
      @selected="onProjectsSelected"
    />
  </div>
</template>
