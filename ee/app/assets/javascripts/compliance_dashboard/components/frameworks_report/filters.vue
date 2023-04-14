<script>
import { GlFilteredSearch } from '@gitlab/ui';

import { __, s__ } from '~/locale';

import { FRAMEWORKS_FILTER_TYPE_FRAMEWORK, FRAMEWORKS_FILTER_TYPE_PROJECT } from '../../constants';
import ComplianceFrameworkToken from './filter_tokens/compliance_framework_token.vue';
import ProjectSearchToken from './filter_tokens/project_search_token.vue';

export default {
  components: {
    GlFilteredSearch,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    rootAncestorPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    filterTokens() {
      return [
        {
          unique: true,
          icon: 'shield',
          title: s__('ComplianceReport|Compliance framework'),
          type: FRAMEWORKS_FILTER_TYPE_FRAMEWORK,
          entityType: 'framework',
          token: ComplianceFrameworkToken,
          rootAncestorPath: this.rootAncestorPath,
        },
        {
          unique: true,
          icon: 'project',
          title: __('Project'),
          type: FRAMEWORKS_FILTER_TYPE_PROJECT,
          entityType: 'project',
          token: ProjectSearchToken,
          operators: [{ value: 'matches', description: 'matches' }],
        },
      ];
    },
  },
  methods: {
    onFilterSubmit(filters) {
      this.$emit('submit', filters);
    },
    handleFilterClear() {
      this.$emit('submit', []);
    },
  },
  i18n: {
    placeholder: __('Search or filter results'),
  },
};
</script>

<template>
  <div class="row-content-block gl-mb-5">
    <gl-filtered-search
      :value="value"
      :placeholder="$options.i18n.placeholder"
      :available-tokens="filterTokens"
      @submit="onFilterSubmit"
      @clear="handleFilterClear"
    />
  </div>
</template>
