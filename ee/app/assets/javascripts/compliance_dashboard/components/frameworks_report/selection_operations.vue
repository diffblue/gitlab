<script>
import Vue from 'vue';
import { GlButton, GlCollapsibleListbox, GlSprintf, GlToast, GlTooltip } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';

import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';
import setComplianceFrameworkMutation from '../../graphql/set_compliance_framework.mutation.graphql';

Vue.use(GlToast);

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlSprintf,
    GlTooltip,
  },
  props: {
    selection: {
      type: Array,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
    newGroupComplianceFrameworkPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedOperation: null,
      selectedFramework: null,
      isApplyInProgress: false,
      frameworkSearchQuery: '',
    };
  },
  apollo: {
    frameworks: {
      query: getComplianceFrameworkQuery,
      variables() {
        return { fullPath: this.groupPath };
      },
      update(data) {
        return data.namespace.complianceFrameworks.nodes;
      },
      skip() {
        return this.selectedOperation !== this.$options.operations.APPLY_OPERATION;
      },
    },
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
        { text: this.$options.i18n.removeFramework, value: 'remove' },
      ];
    },
    frameworksDropdownItems() {
      return (this.frameworks ?? [])
        .filter((entry) =>
          entry.name.toLowerCase().includes(this.frameworkSearchQuery.toLowerCase()),
        )
        .map((entry) => ({
          text: entry.name,
          color: entry.color,
          value: entry.id,
          extraAttrs: {},
        }));
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
  },

  methods: {
    reset() {
      this.selectedOperation = null;
      this.selectedFramework = null;
    },

    async applyOperations(operations) {
      const successMessage = operations.some((entry) => Boolean(entry.frameworkId))
        ? this.$options.i18n.successApplyToastMessage
        : this.$options.i18n.successRemoveToastMessage;

      try {
        this.isApplyInProgress = true;
        const results = await Promise.all(
          operations.map((entry) =>
            this.$apollo.mutate({
              mutation: setComplianceFrameworkMutation,
              variables: {
                projectId: entry.projectId,
                frameworkId: entry.frameworkId,
              },
            }),
          ),
        );

        const firstError = results.some(
          (response) => response.data.projectSetComplianceFramework.errors.length,
        );
        if (firstError) {
          throw firstError;
        }
        this.$toast.show(successMessage, {
          action: {
            text: __('Undo'),
            onClick: () => {
              this.applyOperations(
                operations.map((entry) => ({
                  projectId: entry.projectId,
                  previousFrameworkId: entry.frameworkId,
                  frameworkId: entry.previousFrameworkId,
                })),
              );
            },
          },
        });
      } catch (e) {
        createAlert({
          message: __('Something went wrong on our end.'),
        });
      } finally {
        this.isApplyInProgress = false;
      }
    },

    async apply() {
      const operations = this.selection.map((project) => ({
        projectId: project.id,
        previousFrameworkId: project.complianceFrameworks?.nodes?.[0]?.id ?? null,
        frameworkId: this.selectedFramework ?? null,
      }));

      this.applyOperations(operations);
    },
  },

  i18n: {
    dropdownActionPlaceholder: s__('ComplianceReport|Choose one bulk action'),
    applyFramework: s__('ComplianceReport|Apply framework to selected projects'),
    removeFramework: s__('ComplianceReport|Remove framework from selected projects'),

    operationSelectionTooltip: s__(
      'ComplianceReport|Select at least one project to apply the bulk action',
    ),

    frameworksDropdownPlaceholder: s__('ComplianceReport|Choose one framework'),
    createNewFramework: s__('ComplianceReport|Create a new framework'),

    successApplyToastMessage: s__('ComplianceReport|Framework successfully applied'),
    successRemoveToastMessage: s__('ComplianceReport|Framework successfully removed'),
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
    <div ref="operations">
      <gl-collapsible-listbox
        v-model="selectedOperation"
        class="gl-pl-5"
        :disabled="!hasSelection"
        :toggle-text="
          selectedOperation ? selectedOperation.text : $options.i18n.dropdownActionPlaceholder
        "
        :header-text="$options.i18n.dropdownActionPlaceholder"
        :items="operationsDropdownItems"
        role="button"
        tabindex="0"
      />
      <gl-collapsible-listbox
        v-if="selectedOperation === $options.operations.APPLY_OPERATION"
        v-model="selectedFramework"
        :disabled="!hasSelection"
        :loading="$apollo.queries.frameworks.loading"
        :toggle-text="
          selectedFramework ? selectedFramework.text : $options.i18n.frameworksDropdownPlaceholder
        "
        :header-text="$options.i18n.frameworksDropdownPlaceholder"
        :items="frameworksDropdownItems"
        searchable
        role="button"
        tabindex="0"
        @search="frameworkSearchQuery = $event"
      >
        <template #list-item="{ item }">
          <div class="gl-display-flex gl-align-items-center">
            <div
              class="gl-display-inline-block gl-w-5 gl-h-3 gl-mr-3 gl-rounded-pill"
              :style="{ backgroundColor: item.color }"
            ></div>
            {{ item.text }}
          </div>
        </template>
        <template #footer>
          <div
            class="gl-border-t-solid gl-border-t-1 gl-border-t-gray-100 gl-display-flex gl-flex-direction-column gl-p-2! gl-pt-0!"
          >
            <gl-button
              category="tertiary"
              block
              class="gl-justify-content-start! gl-mt-2!"
              :href="newGroupComplianceFrameworkPath"
            >
              {{ $options.i18n.createNewFramework }}
            </gl-button>
          </div>
        </template>
      </gl-collapsible-listbox>
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
