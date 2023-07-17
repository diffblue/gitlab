<script>
import UsageBanner from '~/vue_shared/components/usage_quotas/usage_banner.vue';
import { s__ } from '~/locale';
import NumberToHumanSize from './number_to_human_size.vue';
import StorageTypeWarning from './storage_type_warning.vue';
import HelpPageLink from './help_page_link.vue';

export default {
  name: 'ContainerRegistryUsage',
  components: {
    NumberToHumanSize,
    StorageTypeWarning,
    UsageBanner,
    HelpPageLink,
  },
  props: {
    containerRegistrySize: {
      type: Number,
      required: true,
      default: 0,
    },
    containerRegistrySizeIsEstimated: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    containerRegistry: s__('UsageQuota|Container Registry'),
    storageUsed: s__('UsageQuota|Storage used'),
    containerRegistryDescription: s__(
      'UsageQuota|Gitlab-integrated Docker Container Registry for storing Docker Images.',
    ),
    estimatedWarningTooltip: s__(
      'UsageQuota|Precise calculation of Container Registry storage size is delayed because it is too large for synchronous estimation. Precise evaluation will be scheduled within 24 hours.',
    ),
  },
};
</script>
<template>
  <usage-banner data-qa-selector="container_registry_usage">
    <template #left-primary-text>
      {{ $options.i18n.containerRegistry }}
    </template>
    <template #left-secondary-text>
      <span>
        {{ $options.i18n.containerRegistryDescription }}
        <help-page-link class="gl-reset-font-size" path="user/packages/container_registry/index">
          {{ __('More information') }}
        </help-page-link>
      </span>
    </template>
    <template #right-primary-text>
      {{ $options.i18n.storageUsed }}
    </template>
    <template #right-secondary-text>
      <number-to-human-size
        :value="containerRegistrySize"
        data-testid="total-size-section"
        data-qa-selector="container_registry_size"
      />
      <storage-type-warning v-if="containerRegistrySizeIsEstimated">
        {{ $options.i18n.estimatedWarningTooltip }}
        <help-page-link
          class="gl-reset-font-size"
          path="user/usage_quotas"
          anchor="delayed-refresh"
        >
          {{ __('Learn more.') }}
        </help-page-link>
      </storage-type-warning>
    </template>
  </usage-banner>
</template>
