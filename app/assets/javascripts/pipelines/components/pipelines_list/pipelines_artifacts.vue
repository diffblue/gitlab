<script>
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlTooltipDirective,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';

export const i18n = {
  artifacts: __('Artifacts'),
  artifactSectionHeader: __('Download artifacts'),
  artifactsFetchErrorMessage: s__('Pipelines|Could not load artifacts.'),
  noArtifacts: s__('Pipelines|No artifacts available'),
};

export default {
  i18n,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAlert,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
  },
  inject: {
    artifactsEndpoint: {
      default: '',
    },
    artifactsEndpointPlaceholder: {
      default: '',
    },
  },
  props: {
    pipelineId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      artifacts: [],
      hasError: false,
      isLoading: false,
    };
  },
  computed: {
    shouldShowDropdown() {
      return this.isLoading || this.hasError || this.artifacts?.length;
    },
  },
  mounted() {
    this.fetchArtifacts();
  },
  methods: {
    fetchArtifacts() {
      this.isLoading = true;
      // Replace the placeholder with the ID of the pipeline we are viewing
      const endpoint = this.artifactsEndpoint.replace(
        this.artifactsEndpointPlaceholder,
        this.pipelineId,
      );
      return axios
        .get(endpoint)
        .then(({ data }) => {
          this.artifacts = data.artifacts;
        })
        .catch(() => {
          this.hasError = true;
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <gl-dropdown
    v-if="shouldShowDropdown"
    v-gl-tooltip
    class="build-artifacts js-pipeline-dropdown-download"
    :title="$options.i18n.artifacts"
    :text="$options.i18n.artifacts"
    :aria-label="$options.i18n.artifacts"
    :loading="isLoading"
    icon="download"
    right
    lazy
    text-sr-only
  >
    <gl-dropdown-section-header>{{
      $options.i18n.artifactSectionHeader
    }}</gl-dropdown-section-header>

    <gl-alert v-if="hasError" variant="danger" :dismissible="false">
      {{ $options.i18n.artifactsFetchErrorMessage }}
    </gl-alert>

    <gl-dropdown-item
      v-for="(artifact, i) in artifacts"
      :key="i"
      :href="artifact.path"
      rel="nofollow"
      download
      class="gl-word-break-word"
    >
      {{ artifact.name }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
