<script>
import { GlLink, GlTruncate } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';

export default {
  name: 'DependencyProjectCount',
  components: {
    GlLink,
    GlTruncate,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
    projectCount: {
      type: Number,
      required: true,
    },
  },
  computed: {
    projectComponent() {
      return this.hasMultipleProjects ? 'span' : GlLink;
    },
    projectPath() {
      const projectAbsolutePath = joinPaths(getBaseURL(), this.project.full_path);

      return this.hasMultipleProjects ? '' : projectAbsolutePath;
    },
    projectText() {
      return this.hasMultipleProjects
        ? sprintf(s__('Dependencies|%{projectCount} projects'), {
            projectCount: Number.isNaN(this.projectCount) ? 0 : this.projectCount,
          })
        : this.project.name;
    },
    hasMultipleProjects() {
      return this.projectCount > 1;
    },
  },
};
</script>

<template>
  <component
    :is="projectComponent"
    class="gl-md-white-space-nowrap"
    data-testid="dependency-project-count"
    :href="projectPath"
  >
    <gl-truncate
      class="gl-display-none gl-md-display-inline-flex"
      position="start"
      :text="projectText"
      with-tooltip
    />
  </component>
</template>
