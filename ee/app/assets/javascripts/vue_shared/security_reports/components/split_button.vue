<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    buttons: {
      type: Array,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedButtonIndex: 0,
    };
  },
  computed: {
    selectedButton() {
      return this.buttons[this.selectedButtonIndex];
    },
  },
  methods: {
    setButton(index) {
      this.selectedButtonIndex = index;
    },
    handleClick() {
      if (this.selectedButton.href) {
        visitUrl(this.selectedButton.href, true);
      } else {
        this.$emit(this.selectedButton.action);
      }
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="selectedButton"
    :disabled="disabled"
    variant="success"
    :text="selectedButton.name"
    :href="selectedButton.href"
    :loading="selectedButton.loading"
    split
    @click="handleClick"
  >
    <gl-dropdown-item
      v-for="(button, index) in buttons"
      :key="button.action"
      :is-checked="selectedButton === button"
      :data-testid="`${button.action}-button`"
      is-check-item
      @click="setButton(index)"
    >
      <strong>{{ button.name }}</strong>
      <br />
      <span>{{ button.tagline }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
