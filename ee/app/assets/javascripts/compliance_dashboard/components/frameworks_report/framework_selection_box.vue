<script>
import * as Sentry from '@sentry/browser';
import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';

const frameworksDropdownPlaceholder = s__('ComplianceReport|Choose one framework');

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
  },
  model: {
    prop: 'selected',
    event: 'select',
  },
  props: {
    newGroupComplianceFrameworkPath: {
      type: String,
      required: true,
    },
    rootAncestorPath: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    selected: {
      type: String,
      required: false,
      default: () => null,
    },
    placeholder: {
      type: String,
      required: false,
      default: frameworksDropdownPlaceholder,
    },
  },
  data() {
    return {
      frameworkSearchQuery: '',
    };
  },
  apollo: {
    frameworks: {
      query: getComplianceFrameworkQuery,
      variables() {
        return { fullPath: this.rootAncestorPath };
      },
      update(data) {
        return data.namespace.complianceFrameworks.nodes;
      },
      error(error) {
        createAlert({
          message: __('Something went wrong on our end.'),
        });
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    toggleText() {
      const selectedFramework = this.frameworks?.find((f) => f.id === this.selected);

      return selectedFramework?.name ?? this.placeholder;
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
  },
  i18n: {
    frameworksDropdownPlaceholder,
    createNewFramework: s__('ComplianceReport|Create a new framework'),
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :selected="selected"
    :loading="$apollo.queries.frameworks.loading"
    :toggle-text="toggleText"
    :disabled="disabled"
    :header-text="$options.i18n.frameworksDropdownPlaceholder"
    :items="frameworksDropdownItems"
    searchable
    role="button"
    tabindex="0"
    @select="$emit('select', $event)"
    @search="frameworkSearchQuery = $event"
  >
    <template v-if="$scopedSlots.toggle" #toggle><slot name="toggle"></slot></template>
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
</template>
