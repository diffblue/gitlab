<script>
import { GlTable, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import NumberToHumanSize from './number_to_human_size.vue';

export default {
  name: 'ProjectList',
  components: {
    GlTable,
    GlLink,
    ProjectAvatar,
    NumberToHumanSize,
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
  },
  fields: [
    { key: 'name', label: s__('UsageQuota|Project') },
    { key: 'storageSize', label: s__('UsageQuota|Total') },
    { key: 'repositorySize', label: s__('UsageQuota|Repository') },
    { key: 'uploadsSize', label: s__('UsageQuota|Uploads') },
    { key: 'snippetsSize', label: s__('UsageQuota|Snippets') },
    { key: 'buildArtifactsSize', label: s__('UsageQuota|Artifacts') },
    { key: 'containerRegistrySize', label: s__('UsageQuota|Container Registry') },
    { key: 'lfsObjectsSize', label: s__('UsageQuota|LFS') },
    { key: 'packagesSize', label: s__('UsageQuota|Packages') },
    { key: 'wikiSize', label: s__('UsageQuota|Wiki') },
  ],
};
</script>

<template>
  <gl-table
    :fields="$options.fields"
    :items="projects"
    :busy="isLoading"
    :show-empty="true"
    :empty-text="s__('UsageQuota|No projects to display.')"
    small
    stacked="lg"
  >
    <template #cell(name)="{ item: project }">
      <project-avatar
        :project-id="project.id"
        :project-name="project.name"
        :project-avatar-url="project.avatarUrl"
        :size="16"
        :alt="project.name"
        class="gl-display-inline-block gl-mr-2 gl-text-center!"
      />

      <gl-link :href="project.webUrl" class="gl-text-gray-900! js-project-link">{{
        project.nameWithNamespace
      }}</gl-link>
    </template>

    <template #cell(storageSize)="{ item: project }">
      <number-to-human-size :value="project.statistics.storageSize" />
    </template>

    <template #cell(repositorySize)="{ item: project }">
      <number-to-human-size :value="project.statistics.repositorySize" />
    </template>
    <template #cell(lfsObjectsSize)="{ item: project }">
      <number-to-human-size :value="project.statistics.lfsObjectsSize" />
    </template>

    <template #cell(containerRegistrySize)="{ item: project }">
      <number-to-human-size :value="project.statistics.containerRegistrySize" />
    </template>

    <template #cell(buildArtifactsSize)="{ item: project }">
      <number-to-human-size :value="project.statistics.buildArtifactsSize" />
    </template>

    <template #cell(packagesSize)="{ item: project }">
      <number-to-human-size :value="project.statistics.packagesSize" />
    </template>

    <template #cell(wikiSize)="{ item: project }">
      <number-to-human-size :value="project.statistics.wikiSize" />
    </template>

    <template #cell(snippetsSize)="{ item: project }">
      <number-to-human-size :value="project.statistics.snippetsSize" />
    </template>

    <template #cell(uploadsSize)="{ item: project }">
      <number-to-human-size :value="project.statistics.uploadsSize" />
    </template>
  </gl-table>
</template>
