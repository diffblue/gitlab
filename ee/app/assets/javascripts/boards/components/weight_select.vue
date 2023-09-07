<script>
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

const ANY_WEIGHT = 'Any weight';
const NO_WEIGHT = 'None';

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
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
    listBoxItems() {
      return this.weights.map((item) => ({ value: item, text: item }));
    },
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

      this.$nextTick(() => {
        this.$refs.dropdown.open();
      });
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
      }
      if (weight === NO_WEIGHT) {
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

    <gl-collapsible-listbox
      v-if="!dropdownHidden"
      ref="dropdown"
      block
      toggle-class="gl-w-full"
      :items="listBoxItems"
      :selected="selected"
      :toggle-text="valueText"
      @select="selectWeight"
    />
  </div>
</template>
