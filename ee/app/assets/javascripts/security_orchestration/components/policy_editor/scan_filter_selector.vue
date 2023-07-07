<script>
import { GlCollapsibleListbox, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import GenericBaseLayoutComponent from './generic_base_layout_component.vue';

export default {
  i18n: {
    buttonText: s__('ScanResultPolicy|Add new criteria'),
    disabledLabel: __('disabled'),
    headerText: s__('ScanResultPolicy|Choose criteria type'),
  },
  name: 'ScanFilterSelector',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GenericBaseLayoutComponent,
    GlCollapsibleListbox,
    GlBadge,
  },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    filters: {
      type: Array,
      required: false,
      default: () => [],
    },
    selected: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    tooltipTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    filterSelected(value) {
      return Boolean(this.selected[value]);
    },
    selectFilter(filter) {
      if (this.filterSelected(filter)) {
        return;
      }

      this.$emit('select', filter);
    },
  },
};
</script>

<template>
  <generic-base-layout-component :show-remove-button="false">
    <template #content>
      <gl-collapsible-listbox
        v-gl-tooltip.right.viewport
        :disabled="disabled"
        fluid-width
        :header-text="$options.i18n.headerText"
        :items="filters"
        :toggle-text="$options.i18n.buttonText"
        :title="tooltipTitle"
        selected="selected"
        variant="link"
        @select="selectFilter"
      >
        <template #list-item="{ item }">
          <div class="gl-display-flex">
            <span
              :id="item.value"
              class="gl-pr-3"
              :class="{ 'gl-text-gray-500': filterSelected(item.value) }"
            >
              {{ item.text }}
            </span>
            <gl-badge
              v-if="filterSelected(item.value)"
              v-gl-tooltip.right.viewport
              class="gl-ml-auto"
              size="sm"
              variant="neutral"
              :title="item.tooltip"
            >
              {{ $options.i18n.disabledLabel }}
            </gl-badge>
          </div>
        </template>
      </gl-collapsible-listbox>
    </template>
  </generic-base-layout-component>
</template>
