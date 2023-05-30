<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';

import CiEditorHeader from '~/ci/pipeline_editor/components/editor/ci_editor_header.vue';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';

export default {
  i18n: {
    browseCatalog: __('Browse CI/CD Catalog'),
  },
  components: {
    CiEditorHeader,
    GlButton,
  },
  mixins: [Tracking.mixin()],
  inject: {
    canViewNamespaceCatalog: { default: false },
    ciCatalogPath: { default: '' },
  },
  methods: {
    trackCatalogBrowsing() {
      const { label, actions } = pipelineEditorTrackingOptions;

      this.track(actions.browseCatalog, { label });
    },
  },
};
</script>

<template>
  <ci-editor-header v-bind="$attrs" v-on="$listeners">
    <gl-button
      v-if="canViewNamespaceCatalog"
      :href="ciCatalogPath"
      size="small"
      icon="external-link"
      target="_blank"
      data-testid="catalog-repo-link"
      data-qa-selector="catalog_repo_link"
      @click="trackCatalogBrowsing"
    >
      {{ $options.i18n.browseCatalog }}
    </gl-button>
  </ci-editor-header>
</template>
