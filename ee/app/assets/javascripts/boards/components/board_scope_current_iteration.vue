<script>
import { GlFormCheckbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { IterationIDs, CURRENT_ITERATION } from '../constants';

export default {
  i18n: {
    label: __('Scope board to current iteration'),
    title: __('Iteration'),
  },
  components: {
    GlFormCheckbox,
  },
  props: {
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    iterationId: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      checked: this.iterationId === IterationIDs.CURRENT,
    };
  },
  methods: {
    handleToggle() {
      this.checked = !this.checked;
      const iteration = this.checked ? CURRENT_ITERATION : { id: null };
      this.$emit('set-iteration', iteration);
    },
  },
};
</script>

<template>
  <div class="block iteration">
    <div class="title gl-mb-3">
      {{ $options.i18n.title }}
    </div>
    <gl-form-checkbox
      :disabled="!canAdminBoard"
      :checked="checked"
      class="gl-text-gray-500"
      data-testid="scope-to-current-iteration"
      @change="handleToggle"
      >{{ $options.i18n.label }}
    </gl-form-checkbox>
  </div>
</template>
