<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import UsageBanner from '~/vue_shared/components/usage_quotas/usage_banner.vue';
import { s__ } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';

export default {
  name: 'ContainerRegistryUsage',
  components: {
    UsageBanner,
    GlSprintf,
    GlLink,
  },
  props: {
    containerRegistrySize: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  i18n: {
    containerRegistry: s__('UsageQuota|Container Registry'),
    storageUsed: s__('UsageQuota|Storage used'),
    containerRegistryDescription: s__(
      'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images. %{linkStart}More information%{linkEnd}',
    ),
  },
  computed: {
    formattedContainerRegistrySize() {
      return numberToHumanSize(this.containerRegistrySize, 1);
    },
  },
  storageUsageQuotaHelpPage: helpPagePath('user/packages/container_registry/index'),
};
</script>
<template>
  <usage-banner data-qa-selector="container_registry_usage">
    <template #left-primary-text>
      {{ $options.i18n.containerRegistry }}
    </template>
    <template #left-secondary-text>
      <div data-testid="container-registry-description">
        <gl-sprintf :message="$options.i18n.containerRegistryDescription">
          <template #link="{ content }">
            <gl-link :href="$options.storageUsageQuotaHelpPage">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </template>
    <template #right-primary-text>
      {{ $options.i18n.storageUsed }}
    </template>
    <template #right-secondary-text>
      <span data-testid="total-size-section" data-qa-selector="container_registry_size">{{
        formattedContainerRegistrySize
      }}</span>
    </template>
  </usage-banner>
</template>
