<script>
import { GlFormGroup } from '@gitlab/ui';
import LabelsSelector from '../labels_selector.vue';

export default {
  name: 'CustomStageEventLabelField',
  components: {
    GlFormGroup,
    LabelsSelector,
  },
  props: {
    index: {
      type: Number,
      required: true,
    },
    eventType: {
      type: String,
      required: true,
    },
    fieldLabel: {
      type: String,
      required: true,
    },
    requiresLabel: {
      type: Boolean,
      required: true,
    },
    hasLabelError: {
      type: Boolean,
      required: false,
      default: false,
    },
    labelError: {
      type: String,
      required: false,
      default: '',
    },
    selectedLabelNames: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    fieldName() {
      const { eventType, index } = this;
      return `custom-stage-${eventType}-label-${index}`;
    },
  },
};
</script>
<template>
  <div class="gl-w-half gl-ml-2">
    <transition name="fade">
      <gl-form-group
        v-if="requiresLabel"
        :data-testid="fieldName"
        :label="fieldLabel"
        :state="hasLabelError"
        :invalid-feedback="labelError"
      >
        <labels-selector
          :selected-label-names="selectedLabelNames"
          :name="fieldName"
          @select-label="$emit('update-label', $event)"
        />
      </gl-form-group>
    </transition>
  </div>
</template>
