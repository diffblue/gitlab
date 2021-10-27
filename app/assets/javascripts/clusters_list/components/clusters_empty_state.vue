<script>
import { GlEmptyState, GlButton, GlLink } from '@gitlab/ui';
import { mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlEmptyState,
    GlButton,
    GlLink,
  },
  inject: ['emptyStateHelpText', 'clustersEmptyStateImage', 'newClusterPath'],
  learnMoreHelpUrl: helpPagePath('user/project/clusters/index'),
  computed: {
    ...mapState(['canAddCluster']),
  },
};
</script>

<template>
  <gl-empty-state
    :svg-path="clustersEmptyStateImage"
    :title="s__('ClusterIntegration|Integrate Kubernetes with a cluster certificate')"
  >
    <template #description>
      <p class="gl-text-left">
        {{
          s__(
            'ClusterIntegration|Kubernetes clusters allow you to use review apps, deploy your applications, run your pipelines, and much more in an easy way.',
          )
        }}
      </p>

      <p v-if="emptyStateHelpText" class="gl-text-left" data-testid="clusters-empty-state-text">
        {{ emptyStateHelpText }}
      </p>

      <p>
        <gl-link :href="$options.learnMoreHelpUrl" target="_blank" data-testid="clusters-docs-link">
          {{ s__('ClusterIntegration|Learn more about Kubernetes') }}
        </gl-link>
      </p>
    </template>

    <template #actions>
      <gl-button
        data-testid="integration-primary-button"
        data-qa-selector="add_kubernetes_cluster_link"
        category="primary"
        variant="confirm"
        :disabled="!canAddCluster"
        :href="newClusterPath"
      >
        {{ s__('ClusterIntegration|Integrate with a cluster certificate') }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
