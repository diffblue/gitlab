<script>
import { GlDropdown, GlDropdownSectionHeader, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';

const SORTING_TITLE = s__('SortOptions|Sort by:');
const SORTING_OPTIONS = [
  {
    key: 'created_desc',
    text: s__('SortOptions|Last created'),
  },
  {
    key: 'created_asc',
    text: s__('SortOptions|Oldest created'),
  },
];

export default {
  components: {
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
  },
  props: {
    sortBy: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    selectedOption() {
      return SORTING_OPTIONS.find((option) => option.key === this.sortBy) || SORTING_OPTIONS[0];
    },
  },
  methods: {
    onItemClick(option) {
      this.$emit('selected', option);
    },
    isChecked(key) {
      return key === this.selectedOption.key;
    },
  },
  SORTING_TITLE,
  SORTING_OPTIONS,
};
</script>

<template>
  <gl-dropdown :text="selectedOption.text" class="gl-display-flex gl-mb-5">
    <gl-dropdown-section-header> {{ $options.SORTING_TITLE }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="option in $options.SORTING_OPTIONS"
      :key="option.key"
      is-check-item
      :is-checked="isChecked(option.key)"
      @click="onItemClick(option.key)"
    >
      {{ option.text }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
