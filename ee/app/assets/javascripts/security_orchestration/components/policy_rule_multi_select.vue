<script>
import { GlButton, GlCollapsibleListbox, GlTruncate } from '@gitlab/ui';

import { s__, sprintf } from '~/locale';

const NO_ITEM_SELECTED = 0;
const ONE_ITEM_SELECTED = 1;

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlTruncate,
  },
  props: {
    itemTypeName: {
      type: String,
      required: true,
    },
    items: {
      type: Object,
      required: true,
    },
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    includeSelectAll: {
      type: Boolean,
      required: false,
      default: () => true,
    },
  },
  data() {
    return {
      selected: [...this.value],
    };
  },
  computed: {
    listBoxItems() {
      return Object.entries(this.items).map(([value, text]) => ({ value, text }));
    },
    listBoxHeader() {
      return sprintf(this.$options.i18n.selectPolicyListboxHeader, {
        itemTypeName: this.itemTypeName,
      });
    },
    text() {
      switch (this.selected.length) {
        case this.itemsKeys.length:
          return sprintf(
            this.$options.i18n.allSelectedLabel,
            { itemTypeName: this.itemTypeName },
            false,
          );
        case NO_ITEM_SELECTED:
          return sprintf(
            this.$options.i18n.selectedItemsLabel,
            {
              itemTypeName: this.itemTypeName,
            },
            false,
          );
        case ONE_ITEM_SELECTED:
          return this.items[this.selected[0]];
        default:
          return sprintf(this.$options.i18n.multipleSelectedLabel, {
            firstLabel: this.items[this.selected[0]],
            numberOfAdditionalLabels: this.selected.length - 1,
          });
      }
    },
    itemsKeys() {
      return Object.keys(this.items);
    },
  },
  methods: {
    setSelected(items) {
      this.selected = [...items];
      this.$emit('input', this.selected);
    },
  },
  i18n: {
    multipleSelectedLabel: s__(
      'PolicyRuleMultiSelect|%{firstLabel} +%{numberOfAdditionalLabels} more',
    ),
    clearAllLabel: s__('PolicyRuleMultiSelect|Clear all'),
    selectAllLabel: s__('PolicyRuleMultiSelect|Select all'),
    selectedItemsLabel: s__('PolicyRuleMultiSelect|Select %{itemTypeName}'),
    selectPolicyListboxHeader: s__('PolicyRuleMultiSelect|Select %{itemTypeName}'),
    allSelectedLabel: s__('PolicyRuleMultiSelect|All %{itemTypeName}'),
  },
};
</script>

<template>
  <gl-collapsible-listbox
    multiple
    :header-text="listBoxHeader"
    :items="listBoxItems"
    :selected="selected"
    :reset-button-label="$options.i18n.clearAllLabel"
    :toggle-text="text"
    @reset="setSelected([])"
    @select="setSelected"
  >
    <template #list-item="{ item }">
      <gl-truncate :text="item.text" />
    </template>
    <template #footer>
      <div
        v-if="includeSelectAll"
        class="gl-border-t-solid gl-border-t-1 gl-border-t-gray-100 gl-display-flex gl-flex-direction-column gl-p-2"
      >
        <gl-button
          category="tertiary"
          class="gl-justify-content-start!"
          data-testid="all-items-selected"
          @click="setSelected(itemsKeys)"
        >
          {{ $options.i18n.selectAllLabel }}
        </gl-button>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
