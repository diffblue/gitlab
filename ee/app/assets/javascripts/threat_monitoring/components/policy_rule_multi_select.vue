<script>
import { GlDropdown, GlDropdownItem, GlTruncate } from '@gitlab/ui';

import { s__, sprintf } from '~/locale';

const INDEX_NOT_FOUND = -1;
const NO_ITEM_SELECTED = 0;
const ONE_ITEM_SELECTED = 1;

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
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
  },
  data() {
    return {
      selected: [...this.value],
    };
  },
  computed: {
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
    areAllSelected() {
      return this.itemsKeys.length === this.selected.length;
    },
    itemsKeys() {
      return Object.keys(this.items);
    },
  },
  methods: {
    setAllSelected() {
      this.selected = this.areAllSelected ? [] : [...this.itemsKeys];
      this.$emit('input', this.selected);
    },
    setSelected(item) {
      const position = this.selected.indexOf(item);
      if (position === INDEX_NOT_FOUND) {
        this.selected.push(item);
      } else {
        this.selected.splice(position, 1);
      }
      this.$emit('input', this.selected);
    },
    isSelected(item) {
      return this.selected.includes(item);
    },
  },
  i18n: {
    multipleSelectedLabel: s__(
      'PolicyRuleMultiSelect|%{firstLabel} +%{numberOfAdditionalLabels} more',
    ),
    selectAllLabel: s__('PolicyRuleMultiSelect|Select all'),
    selectedItemsLabel: s__('PolicyRuleMultiSelect|Select %{itemTypeName}'),
    allSelectedLabel: s__('PolicyRuleMultiSelect|All %{itemTypeName}'),
  },
  ALL_KEY: 'all',
};
</script>

<template>
  <gl-dropdown :text="text">
    <gl-dropdown-item
      :key="$options.ALL_KEY"
      is-check-item
      :is-checked="areAllSelected"
      data-testid="all-items-selected"
      @click.native.capture.stop="setAllSelected"
    >
      {{ $options.i18n.selectAllLabel }}
    </gl-dropdown-item>
    <gl-dropdown-item
      v-for="(label, key) in items"
      :key="key"
      is-check-item
      :is-checked="isSelected(key)"
      @click.native.capture.stop="setSelected(key)"
    >
      <gl-truncate :text="label" />
    </gl-dropdown-item>
  </gl-dropdown>
</template>
