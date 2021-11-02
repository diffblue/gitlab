<script>
import { GlEmptyState, GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  i18n: {
    description: s__(
      'ClusterIntegration|Use certificates to integrate with your clusters to deploy your applications, run your pipelines, use review apps and much more in an easy way.',
    ),
    multipleClustersText: s__(
      'ClusterIntegration|If you are setting up multiple clusters and are using Auto DevOps, %{linkStart}read about using multiple Kubernetes clusters first.%{linkEnd}',
    ),
    learnMoreLinkText: s__('ClusterIntegration|Learn more about the GitLab managed clusters'),
    buttonText: s__('ClusterIntegration|Integrate with a cluster certificate'),
  },
  components: {
    GlEmptyState,
    GlButton,
    GlLink,
    GlSprintf,
  },
  inject: ['emptyStateHelpText', 'clustersEmptyStateImage', 'newClusterPath'],
  learnMoreHelpUrl: helpPagePath('user/project/clusters/index'),
  computed: {
    ...mapState(['canAddCluster']),
  },
};
</script>

<template>
  <gl-empty-state :svg-path="clustersEmptyStateImage" title="">
    <template #description>
      <p class="gl-text-left">
        {{ $options.i18n.description }}
      </p>
      <p class="gl-text-left">
        <gl-sprintf :message="$options.i18n.multipleClustersText">
          <template #link="{ content }">
            <gl-link
              :href="$options.multipleClustersHelpUrl"
              target="_blank"
              data-testid="multiple-clusters-docs-link"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>

      <p v-if="emptyStateHelpText" data-testid="clusters-empty-state-text">
        {{ emptyStateHelpText }}
      </p>

      <p>
        <gl-link :href="$options.learnMoreHelpUrl" target="_blank" data-testid="clusters-docs-link">
          {{ $options.i18n.learnMoreLinkText }}
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
        {{ $options.i18n.buttonText }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
