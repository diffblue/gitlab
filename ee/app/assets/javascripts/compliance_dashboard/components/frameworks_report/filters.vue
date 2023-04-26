<script>
import { GlButton, GlFilteredSearch, GlPopover } from '@gitlab/ui';

import { __, s__ } from '~/locale';

import { FRAMEWORKS_FILTER_TYPE_FRAMEWORK, FRAMEWORKS_FILTER_TYPE_PROJECT } from '../../constants';
import ComplianceFrameworkToken from './filter_tokens/compliance_framework_token.vue';
import ProjectSearchToken from './filter_tokens/project_search_token.vue';

export default {
  components: {
    GlButton,
    GlFilteredSearch,
    GlPopover,
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
    showUpdatePopover: {
      type: Boolean,
      required: false,
      default: false,
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
    onFilterSubmit(newFilters) {
      this.$emit('submit', newFilters ?? this.value);
    },
    handleFilterClear() {
      this.$emit('submit', []);
    },
  },
  i18n: {
    placeholder: __('Search or filter results'),
    updatePopoverTitle: s__('ComplianceReport|Update filtered results?'),
    updatePopoverContent: s__(
      'ComplianceReport|Do you want to refresh the filtered results to include your change?',
    ),
    updatePopoverAction: s__('ComplianceReport|Update result'),
  },
};
</script>

<template>
  <div class="row-content-block gl-mb-5 gl-relative">
    <gl-popover
      ref="popover"
      :target="() => $refs.popoverTarget"
      :show="showUpdatePopover"
      show-close-button
      placement="bottomright"
      triggers="manual"
      :title="$options.i18n.updatePopoverTitle"
      @hidden="$emit('update-popover-hidden')"
    >
      {{ $options.i18n.updatePopoverContent }}
      <div class="gl-mt-4">
        <gl-button size="small" category="primary" variant="confirm" @click="onFilterSubmit()">
          {{ $options.i18n.updatePopoverAction }}
        </gl-button>
        <gl-button
          size="small"
          category="secondary"
          variant="reset"
          @click="$refs.popover.$emit('close')"
        >
          {{ __('Dismiss') }}
        </gl-button>
      </div>
    </gl-popover>
    <span ref="popoverTarget" class="gl-absolute gl-h-7 gl-ml-5 gl-pointer-events-none">
      &nbsp;
    </span>
    <gl-filtered-search
      :value="value"
      :placeholder="$options.i18n.placeholder"
      :available-tokens="filterTokens"
      @submit="onFilterSubmit"
      @clear="handleFilterClear"
    />
  </div>
</template>
