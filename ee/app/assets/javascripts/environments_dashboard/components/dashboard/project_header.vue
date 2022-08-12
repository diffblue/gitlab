<script>
import { GlDropdown, GlDropdownItem, GlTooltipDirective, GlLink, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlIcon,
    ProjectAvatar,
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
  },
  methods: {
    onRemove() {
      this.$emit('remove', this.project.remove_path);
    },
  },

  removeProjectText: s__('EnvironmentsDashboard|Remove'),
  moreActionsText: s__('EnvironmentsDashboard|More actions'),
  avatarSize: 24,
};
</script>

<template>
  <div
    class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-justify-content-space-between gl-pb-3 gl-mb-5 gl-border-b-solid gl-border-gray-100 gl-border-1"
  >
    <div class="gl-display-flex gl-align-items-center">
      <project-avatar
        :project-id="project.namespace.id"
        :project-name="project.namespace.name"
        :project-avatar-url="project.namespace.avatar_url"
        :size="$options.avatarSize"
        class="gl-mr-3"
      />
      <gl-link
        class="gl-text-gray-500 gl-mr-3"
        :href="`/${project.namespace.full_path}`"
        data-testid="namespace-link"
      >
        {{ project.namespace.name }}
      </gl-link>

      <span class="gl-mr-3">&gt;</span>

      <project-avatar
        :project-id="project.id"
        :project-name="project.name"
        :project-avatar-url="project.avatar_url"
        :size="$options.avatarSize"
        class="gl-mr-3"
      />
      <gl-link class="gl-text-gray-500 gl-mr-3" :href="project.web_url" data-testid="project-link">
        {{ project.name }}
      </gl-link>
    </div>
    <div class="gl-display-flex">
      <gl-dropdown
        toggle-class="gl-display-flex gl-align-items-center gl-px-3! gl-bg-transparent gl-shadow-none!"
        right
      >
        <template #button-content>
          <gl-icon
            v-gl-tooltip
            :title="$options.moreActionsText"
            name="ellipsis_v"
            class="gl-text-gray-500"
          />
        </template>
        <gl-dropdown-item variant="link" data-testid="remove-project-button" @click="onRemove()">
          <span class="gl-text-red-500"> {{ $options.removeProjectText }} </span>
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
  </div>
</template>
