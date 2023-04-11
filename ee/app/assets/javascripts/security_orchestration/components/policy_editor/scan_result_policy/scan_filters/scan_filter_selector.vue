<script>
import { GlButton, GlCollapsibleListbox, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import BaseLayoutComponent from '../base_layout/base_layout_component.vue';
import { FILTERS, TOOLTIPS } from './constants';

export default {
  FILTERS,
  TOOLTIPS,
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
    BaseLayoutComponent,
    GlButton,
    GlCollapsibleListbox,
    GlBadge,
  },
  props: {
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  methods: {
    filterSelected(filter) {
      return this.selected.includes(filter);
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
  <base-layout-component :show-label="false" :show-remove-button="false">
    <template #content>
      <gl-collapsible-listbox
        :header-text="$options.i18n.headerText"
        :items="$options.FILTERS"
        @select="selectFilter"
      >
        <template #toggle>
          <gl-button variant="link" data-testid="add-rule">
            {{ $options.i18n.buttonText }}
          </gl-button>
        </template>
        <template #list-item="{ item }">
          <div class="gl-display-flex">
            <span :id="item.value" :class="{ 'gl-text-gray-500': filterSelected(item.value) }">
              {{ item.text }}
            </span>
            <gl-badge
              v-if="filterSelected(item.value)"
              v-gl-tooltip.right.viewport
              class="gl-ml-auto"
              size="sm"
              variant="neutral"
              :title="$options.TOOLTIPS[item.value]"
            >
              {{ $options.i18n.disabledLabel }}
            </gl-badge>
          </div>
        </template>
      </gl-collapsible-listbox>
    </template>
  </base-layout-component>
</template>
