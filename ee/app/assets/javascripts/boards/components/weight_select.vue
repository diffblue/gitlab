<script>
import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';

const ANY_WEIGHT = 'Any weight';
const NO_WEIGHT = 'None';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    board: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    weights: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dropdownHidden: true,
      selected: this.board.weight,
    };
  },
  computed: {
    valueClass() {
      if (this.valueText === ANY_WEIGHT) {
        return 'text-secondary';
      }
      return 'bold';
    },
    valueText() {
      const weight = this.selected;
      if (weight > 0 || weight === 0) return weight.toString();
      if (weight === -2) return NO_WEIGHT;
      return ANY_WEIGHT;
    },
  },
  methods: {
    showDropdown() {
      this.dropdownHidden = false;
      this.$refs.dropdown.$children[0].show();
    },
    selectWeight(rawWeight) {
      const weight = this.weightInt(rawWeight);
      this.selected = weight;
      this.dropdownHidden = true;
      this.$emit('set-weight', weight);
    },
    weightInt(weight) {
      if (weight >= 0) {
        return weight;
      } else if (weight === NO_WEIGHT) {
        return -2;
      }
      return null;
    },
    toggleEdit() {
      if (this.dropdownHidden) {
        this.showDropdown();
      } else {
        this.dropdownHidden = true;
      }
    },
  },
  i18n: {
    label: s__('BoardScope|Weight'),
    selectWeight: s__('BoardScope|Select weight'),
    edit: s__('BoardScope|Edit'),
  },
};
</script>

<template>
  <div class="block weight">
    <div class="title gl-mb-3">
      {{ $options.i18n.label }}
      <gl-button
        v-if="canEdit"
        category="tertiary"
        size="small"
        class="edit-link float-right"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div v-if="dropdownHidden" :class="valueClass" data-testid="selected-weight">
      {{ valueText }}
    </div>

    <gl-dropdown
      ref="dropdown"
      :hidden="dropdownHidden"
      :text="valueText"
      menu-class="gl-w-full!"
      class="gl-w-full"
    >
      <gl-dropdown-item
        v-for="weight in weights"
        :key="weight"
        :value="weight"
        @click="selectWeight(weight)"
      >
        {{ weight }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
