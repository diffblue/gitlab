<script>
import { GlButton, GlCollapsibleListbox, GlSprintf, GlTooltip } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import FrameworkSelectionBox from './framework_selection_box.vue';

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlSprintf,
    GlTooltip,

    FrameworkSelectionBox,
  },
  props: {
    selection: {
      type: Array,
      required: true,
    },
    isApplyInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    rootAncestorPath: {
      type: String,
      required: true,
    },
    newGroupComplianceFrameworkPath: {
      type: String,
      required: true,
    },
    defaultFramework: {
      type: Object,
      required: false,
      default: () => null,
    },
  },
  data() {
    return {
      selectedOperation: null,
      selectedFramework: this.defaultFramework?.id ?? null,
      frameworkSearchQuery: '',
    };
  },

  computed: {
    hasSelection() {
      return this.selection.length > 0;
    },

    operationsDropdownItems() {
      return [
        {
          text: this.$options.i18n.applyFramework,
          value: this.$options.operations.APPLY_OPERATION,
        },
        {
          text: this.$options.i18n.removeFramework,
          value: this.$options.operations.REMOVE_OPERATION,
        },
      ];
    },

    isSelectionValid() {
      return (
        this.selectedOperation === this.$options.operations.REMOVE_OPERATION ||
        (this.selectedOperation === this.$options.operations.APPLY_OPERATION &&
          this.selectedFramework)
      );
    },

    actionButtonText() {
      if (this.selectedOperation === this.$options.operations.REMOVE_OPERATION) {
        return __('Remove');
      }

      return __('Apply');
    },

    actionButtonVariant() {
      if (this.selectedOperation === this.$options.operations.REMOVE_OPERATION) {
        return 'danger';
      }

      return 'confirm';
    },
  },

  watch: {
    selectedOperation() {
      this.selectedFramework = null;
    },

    defaultFramework() {
      this.selectedFramework = this.defaultFramework.id;
    },
  },

  methods: {
    reset() {
      this.selectedOperation = null;
      this.selectedFramework = null;
    },

    async apply() {
      const operations = this.selection.map((project) => ({
        projectId: project.id,
        previousFrameworkId: project.complianceFrameworks?.nodes?.[0]?.id ?? null,
        frameworkId: this.selectedFramework ?? null,
      }));

      this.$emit('change', operations);
    },
  },

  i18n: {
    dropdownActionPlaceholder: s__('ComplianceReport|Choose one bulk action'),
    applyFramework: s__('ComplianceReport|Apply framework to selected projects'),
    removeFramework: s__('ComplianceReport|Remove framework from selected projects'),

    operationSelectionTooltip: s__(
      'ComplianceReport|Select at least one project to apply the bulk action',
    ),
  },

  operations: {
    APPLY_OPERATION: 'apply',
    REMOVE_OPERATION: 'remove',
  },
};
</script>

<template>
  <section
    class="gl-border-gray-100 gl-border-solid gl-border-1 gl-p-5 gl-display-flex gl-align-items-center"
  >
    <span class="gl-border-0 gl-border-r-1 gl-border-gray-100 gl-border-solid gl-pr-5">
      <gl-sprintf :message="__('%{count} selected')">
        <template #count>
          <span class="gl-font-weight-bold"> {{ selection.length }}</span>
        </template>
      </gl-sprintf>
    </span>
    <gl-tooltip :target="() => $refs.operations" :disabled="hasSelection">
      {{ $options.i18n.operationSelectionTooltip }}
    </gl-tooltip>
    <div ref="operations" class="gl-pl-5">
      <gl-collapsible-listbox
        v-model="selectedOperation"
        class="gl-mr-2"
        :disabled="!hasSelection"
        :toggle-text="
          selectedOperation ? selectedOperation.text : $options.i18n.dropdownActionPlaceholder
        "
        :header-text="$options.i18n.dropdownActionPlaceholder"
        :items="operationsDropdownItems"
        role="button"
        tabindex="0"
      />
      <framework-selection-box
        v-if="selectedOperation === $options.operations.APPLY_OPERATION"
        v-model="selectedFramework"
        :disabled="!hasSelection"
        :new-group-compliance-framework-path="newGroupComplianceFrameworkPath"
        :root-ancestor-path="rootAncestorPath"
        @create="$emit('create')"
      />
    </div>

    <gl-button variant="reset" class="gl-ml-auto" :disabled="!selectedOperation" @click="reset">
      {{ __('Cancel') }}
    </gl-button>
    <gl-button
      class="gl-ml-3"
      :variant="actionButtonVariant"
      :disabled="!isSelectionValid || isApplyInProgress"
      :loading="isApplyInProgress"
      @click="apply"
    >
      {{ actionButtonText }}
    </gl-button>
  </section>
</template>
