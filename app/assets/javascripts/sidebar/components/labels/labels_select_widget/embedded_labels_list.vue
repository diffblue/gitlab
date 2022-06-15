<script>
import { GlLabel } from '@gitlab/ui';
import { sortBy } from 'lodash';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLabel,
  },
  inject: ['allowScopedLabels'],
  props: {
    disableLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedLabels: {
      type: Array,
      required: true,
    },
    allowLabelRemove: {
      type: Boolean,
      required: true,
    },
    labelsFilterBasePath: {
      type: String,
      required: true,
    },
    labelsFilterParam: {
      type: String,
      required: true,
    },
  },
  computed: {
    sortedSelectedLabels() {
      return sortBy(this.selectedLabels, (label) => (isScopedLabel(label) ? 0 : 1));
    },
  },
  methods: {
    labelFilterUrl(label) {
      return `${this.labelsFilterBasePath}?${this.labelsFilterParam}[]=${encodeURIComponent(
        label.title,
      )}`;
    },
    scopedLabel(label) {
      return this.allowScopedLabels && isScopedLabel(label);
    },
    removeLabel(labelId) {
      this.$emit('onLabelRemove', labelId);
    },
  },
};
</script>

<template>
  <div :class="{ 'gl-mt-4': selectedLabels.length }" data-testid="embedded-labels-list">
    <gl-label
      v-for="label in sortedSelectedLabels"
      :key="label.id"
      class="gl-mr-2 gl-mb-2"
      data-qa-selector="embedded_labels_list_label"
      :data-qa-label-name="label.title"
      :title="label.title"
      :description="label.description"
      :background-color="label.color"
      :target="labelFilterUrl(label)"
      :scoped="scopedLabel(label)"
      :show-close-button="allowLabelRemove"
      :disabled="disableLabels"
      tooltip-placement="top"
      @close="removeLabel(label.id)"
    />
  </div>
</template>
