<script>
import { GlCollapsibleListbox, GlTruncate } from '@gitlab/ui';

import { s__, sprintf } from '~/locale';

const NO_ITEM_SELECTED = 0;
const ONE_ITEM_SELECTED = 1;

export default {
  components: {
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
    selectAllLabel() {
      return this.includeSelectAll ? this.$options.i18n.selectAllLabel : '';
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
    data-testid="policy-rule-multi-select"
    :header-text="listBoxHeader"
    :items="listBoxItems"
    :selected="selected"
    :show-select-all-button-label="selectAllLabel"
    :reset-button-label="$options.i18n.clearAllLabel"
    :toggle-text="text"
    @reset="setSelected([])"
    @select="setSelected"
    @select-all="setSelected(itemsKeys)"
  >
    <template #list-item="{ item }">
      <gl-truncate :text="item.text" />
    </template>
  </gl-collapsible-listbox>
</template>
