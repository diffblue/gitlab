<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import UsageBanner from '~/vue_shared/components/usage_quotas/usage_banner.vue';
import { s__ } from '~/locale';

export default {
  name: 'DependencyProxyUsage',
  components: {
    UsageBanner,
    GlSprintf,
    GlLink,
  },
  props: {
    dependencyProxyTotalSize: {
      type: String,
      required: false,
      default: '',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    dependencyProxy: s__('UsageQuota|Dependency proxy'),
    storageUsed: s__('UsageQuota|Storage used'),
    dependencyProxyMessage: s__(
      'UsageQuota|Local proxy used for frequently-accessed upstream Docker images. %{linkStart}More information%{linkEnd}',
    ),
  },
  storageUsageQuotaHelpPage: helpPagePath('user/packages/dependency_proxy/index'),
};
</script>
<template>
  <usage-banner :loading="loading" data-qa-selector="dependency_proxy_usage">
    <template #left-primary-text>
      {{ $options.i18n.dependencyProxy }}
    </template>
    <template #left-secondary-text>
      <div data-testid="dependency-proxy-description">
        <gl-sprintf :message="$options.i18n.dependencyProxyMessage">
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
      <span data-testid="total-size-section" data-qa-selector="dependency_proxy_size">{{
        dependencyProxyTotalSize
      }}</span>
    </template>
  </usage-banner>
</template>
