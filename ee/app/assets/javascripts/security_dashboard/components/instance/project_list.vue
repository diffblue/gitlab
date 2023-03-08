<script>
import { GlBadge, GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import projectsQuery from 'ee/security_dashboard/graphql/queries/instance_projects.query.graphql';
import { PROJECT_LOADING_ERROR_MESSAGE } from 'ee/security_dashboard/helpers';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  i18n: {
    projectsAdded: s__('SecurityReports|Projects added'),
    removeLabel: s__('SecurityReports|Remove project from dashboard'),
    emptyMessage: s__(
      'SecurityReports|Select a project to add by using the project search field above.',
    ),
  },
  components: {
    GlBadge,
    GlButton,
    GlLoadingIcon,
    ProjectAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  apollo: {
    projects: {
      query: projectsQuery,
      update(data) {
        const projects = data?.instance?.projects?.edges?.map((p) => p.node);

        if (projects === undefined) {
          this.showErrorFlash();
        }

        return projects || [];
      },
      error() {
        this.showErrorFlash();
      },
    },
  },
  data() {
    return {
      projects: [],
    };
  },
  computed: {
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading;
    },
  },
  methods: {
    projectRemoved(project) {
      this.$emit('projectRemoved', project);
    },
    showErrorFlash() {
      createAlert({ message: PROJECT_LOADING_ERROR_MESSAGE });
    },
  },
};
</script>

<template>
  <section>
    <h5
      class="gl-font-weight-bold gl-text-gray-500 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-mb-5 gl-pb-3"
    >
      {{ $options.i18n.projectsAdded }}
      <gl-badge class="gl-font-weight-bold">{{ projects.length }}</gl-badge>
    </h5>
    <gl-loading-icon v-if="isLoadingProjects" size="lg" />
    <ul v-else-if="projects.length" class="gl-p-0">
      <li
        v-for="project in projects"
        :key="project.id"
        class="gl-display-flex gl-align-items-center gl-py-2 js-projects-list-project-item"
      >
        <project-avatar
          class="gl-mr-3"
          :project-id="project.id"
          :project-name="project.name"
          :project-avatar-url="project.avatarUrl"
        />
        {{ project.nameWithNamespace }}
        <gl-button
          v-gl-tooltip
          icon="remove"
          class="gl-ml-auto js-projects-list-project-remove"
          :title="$options.i18n.removeLabel"
          :aria-label="$options.i18n.removeLabel"
          @click="projectRemoved(project)"
        />
      </li>
    </ul>
    <p v-else class="gl-text-gray-500 js-projects-list-empty-message" data-testid="empty-message">
      {{ $options.i18n.emptyMessage }}
    </p>
  </section>
</template>
