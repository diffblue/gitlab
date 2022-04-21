<script>
import { GlSprintf } from '@gitlab/ui';
import { decimalBytes } from '~/lib/utils/unit_format';
import { s__ } from '~/locale';

export default {
  components: {
    GlSprintf,
  },
  i18n: {
    totalSize: s__('CorpusManagement|Total Size: %{totalSize}'),
  },
  props: {
    totalSize: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    formattedFileSize() {
      return decimalBytes(this.totalSize, 0, { unitSeparator: ' ' });
    },
  },
};
</script>
<template>
  <div
    class="gl-h-11 gl-bg-gray-10 gl-display-flex gl-justify-content-space-between gl-align-items-center"
  >
    <div v-if="totalSize" class="gl-ml-5">
      <gl-sprintf :message="$options.i18n.totalSize">
        <template #totalSize>
          <span data-testid="total-size" class="gl-font-weight-bold">{{ formattedFileSize }}</span>
        </template>
      </gl-sprintf>
    </div>
    <slot name="action"></slot>
  </div>
</template>
