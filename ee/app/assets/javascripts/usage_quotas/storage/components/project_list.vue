<script>
import { GlTable, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { namespaceContainerRegistryPopoverContent } from '../constants';
import NumberToHumanSize from './number_to_human_size.vue';
import StorageTypeHelpLink from './storage_type_help_link.vue';
import StorageTypeWarning from './storage_type_warning.vue';

export default {
  name: 'ProjectList',
  components: {
    GlTable,
    GlLink,
    ProjectAvatar,
    NumberToHumanSize,
    StorageTypeHelpLink,
    StorageTypeWarning,
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
    helpLinks: {
      type: Object,
      required: true,
    },
    sortBy: {
      type: String,
      required: true,
    },
    sortDesc: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    /**
     * Builds a gl-table td cell slot name for particular field
     * @param {string} key
     * @returns {string} */
    getHeaderSlotName(key) {
      return `head(${key})`;
    },
    getUsageQuotasUrl(projectUrl) {
      return `${projectUrl}/-/usage_quotas`;
    },
  },
  fields: [
    { key: 'name', label: __('Project') },
    { key: 'storage', label: __('Total'), sortable: true },
    { key: 'repository', label: __('Repository') },
    { key: 'snippets', label: __('Snippets') },
    { key: 'buildArtifacts', label: __('Artifacts') },
    { key: 'containerRegistry', label: __('Container Registry') },
    { key: 'lfsObjects', label: __('LFS') },
    { key: 'packages', label: __('Packages') },
    { key: 'wiki', label: __('Wiki') },
  ].map((f) => ({
    ...f,
    tdClass: 'gl-px-3!',
    thClass: 'gl-px-3!',
  })),
  i18n: {
    namespaceContainerRegistryPopoverContent,
  },
};
</script>

<template>
  <gl-table
    :fields="$options.fields"
    :items="projects"
    :busy="isLoading"
    show-empty
    :empty-text="s__('UsageQuota|No projects to display.')"
    small
    stacked="lg"
    :sort-by="sortBy"
    :sort-desc="sortDesc"
    no-local-sorting
    no-sort-reset
    @sort-changed="$emit('sortChanged', $event)"
  >
    <template v-for="field in $options.fields" #[getHeaderSlotName(field.key)]>
      <div :key="field.key" :data-testid="'th-' + field.key">
        {{ field.label }}

        <storage-type-help-link
          v-if="field.key in helpLinks"
          :storage-type="field.key"
          :help-links="helpLinks"
        />
      </div>
    </template>

    <template #cell(name)="{ item: project }">
      <project-avatar
        :project-id="project.id"
        :project-name="project.name"
        :project-avatar-url="project.avatarUrl"
        :size="16"
        :alt="project.name"
        class="gl-display-inline-block gl-mr-2 gl-text-center!"
      />

      <gl-link
        :href="getUsageQuotasUrl(project.webUrl)"
        class="gl-text-gray-900! js-project-link"
        data-testid="project-link"
        >{{ project.nameWithNamespace }}</gl-link
      >
    </template>

    <template #cell(storage)="{ item: project }">
      <number-to-human-size :value="project.statistics.storageSize" />
    </template>

    <template #cell(repository)="{ item: project }">
      <number-to-human-size :value="project.statistics.repositorySize" />
    </template>

    <template #cell(lfsObjects)="{ item: project }">
      <number-to-human-size :value="project.statistics.lfsObjectsSize" />
    </template>

    <template #cell(containerRegistry)="{ item: project }">
      <div :data-testid="`cell-${project.id}-storage-type-container-registry`">
        <number-to-human-size :value="project.statistics.containerRegistrySize" />

        <storage-type-warning :content="$options.i18n.namespaceContainerRegistryPopoverContent" />
      </div>
    </template>

    <template #cell(buildArtifacts)="{ item: project }">
      <number-to-human-size :value="project.statistics.buildArtifactsSize" />
    </template>

    <template #cell(packages)="{ item: project }">
      <number-to-human-size :value="project.statistics.packagesSize" />
    </template>

    <template #cell(wiki)="{ item: project }">
      <number-to-human-size :value="project.statistics.wikiSize" />
    </template>

    <template #cell(snippets)="{ item: project }">
      <number-to-human-size :value="project.statistics.snippetsSize" />
    </template>
  </gl-table>
</template>
