<script>
import { GlButton, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  components: {
    ProjectAvatar,
    GlButton,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
    hasPipelineFailed: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasErrors: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return __('Remove card');
    },
    headerClasses() {
      return {
        'dashboard-card-header-warning': this.hasErrors,
        'dashboard-card-header-failed': this.hasPipelineFailed,
        'bg-light': !this.hasErrors && !this.hasPipelineFailed,
      };
    },
  },
  methods: {
    onRemove() {
      this.$emit('remove', this.project.remove_path);
    },
  },
};
</script>

<template>
  <div
    :class="headerClasses"
    class="card-header gl-border-0 gl-py-3 gl-display-flex gl-align-items-center"
  >
    <project-avatar
      :project-id="project.id"
      :project-name="project.name"
      :project-avatar-url="project.avatar_url"
      :size="24"
      class="gl-mr-3"
    />
    <div class="gl-flex-grow-1 block-truncated">
      <gl-link
        v-gl-tooltip
        class="gl-text-black-normal"
        :href="project.web_url"
        :title="project.name_with_namespace"
        data-testid="project-link"
      >
        <span data-testid="project-namespace">{{ project.namespace.name }} /</span>
        <span class="gl-font-weight-bold" data-testid="project-name"> {{ project.name }}</span>
      </gl-link>
    </div>
    <gl-button
      v-gl-tooltip
      category="tertiary"
      :title="title"
      :aria-label="title"
      icon="close"
      data-qa-selector="remove_project_button"
      data-testid="remove-project-button"
      @click="onRemove"
    />
  </div>
</template>
