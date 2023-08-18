<script>
import { GlIcon, GlDisclosureDropdown, GlTruncate } from '@gitlab/ui';
import { firstSentenceOfText } from './inline_findings_dropdown_utils';

export default {
  components: {
    GlIcon,
    GlDisclosureDropdown,
    GlTruncate,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    iconId: {
      type: String,
      required: false,
      default: '',
    },
    iconKey: {
      type: String,
      required: false,
      default: '',
    },
    iconName: {
      type: String,
      required: false,
      default: '',
    },
    iconClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    firstSentence(text) {
      return firstSentenceOfText(text);
    },
    emitMouseEnter() {
      this.$emit('mouseenter');
    },
    emitMouseLeave() {
      this.$emit('mouseleave');
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :items="items"
    :fluid-width="true"
    positioning-strategy="absolute"
    class="gl-white-space-normal gl-text-body! findings-dropdown"
  >
    <template #group-label="{ group }">
      {{ group.name }}
    </template>

    <template #list-item="{ item }">
      <span class="gl-display-flex gl-align-items-center gl-text-gray-600">
        <gl-icon
          :size="12"
          :name="item.name"
          :class="item.class"
          class="inline-findings-severity-icon gl-mr-4"
        />
        <span
          class="gl-white-space-nowrap! gl-text-truncate gl-display-flex findings-dropdown-width"
          ><span class="gl-font-weight-bold text-capitalize gl-text-black-normal"
            >{{ item.severity }}: </span
          ><gl-truncate :text="firstSentence(item.text)"
        /></span>
      </span>
    </template>
    <template #toggle>
      <gl-icon
        :id="iconId"
        ref="firstInlineFindingsIcon"
        :key="iconKey"
        :name="iconName"
        :class="iconClass"
        data-testid="toggle-icon"
        class="gl-hover-cursor-pointer gl-relative gl-top-1 inline-findings-severity-icon gl-vertical-align-baseline!"
        @mouseenter="emitMouseEnter"
        @mouseleave="emitMouseLeave"
      />
    </template>
  </gl-disclosure-dropdown>
</template>
