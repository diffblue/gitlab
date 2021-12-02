<script>
import { GlLink, GlIcon, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    link: {
      type: Object,
      required: false,
      default: () => ({ text: '', url: '' }),
    },
    description: {
      type: String,
      required: true,
    },
    usage: {
      type: Object,
      required: true,
    },
    usageTotal: {
      type: Object,
      required: false,
      default: null,
    },
    cssClass: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <div class="gl-p-5 gl-my-5 gl-bg-gray-10 gl-flex-grow-1 gl-white-space-nowrap" :class="cssClass">
    <p class="mb-2">
      <gl-sprintf :message="__('%{size} %{unit}')">
        <template #size>
          <span class="gl-font-size-h-display gl-font-weight-bold">{{ usage.value }}</span>
        </template>
        <template #unit>
          <span class="gl-font-lg gl-font-weight-bold">{{ usage.unit }}</span>
        </template>
      </gl-sprintf>
      <template v-if="usageTotal">
        <span class="gl-font-size-h-display gl-font-weight-bold">/</span>
        <gl-sprintf :message="__('%{size} %{unit}')">
          <template #size>
            <span class="gl-font-size-h-display gl-font-weight-bold">{{ usageTotal.value }}</span>
          </template>
          <template #unit>
            <span class="gl-font-lg gl-font-weight-bold">{{ usageTotal.unit }}</span>
          </template>
        </gl-sprintf>
      </template>
    </p>
    <p class="gl-border-b-2 gl-border-b-solid gl-border-b-gray-100 gl-font-weight-bold gl-pb-3">
      {{ description }}
    </p>
    <p
      class="gl-mb-0 gl-text-gray-900 gl-font-sm gl-white-space-normal"
      data-testid="statistics-card-footer"
    >
      <slot v-bind="{ link }" name="footer">
        <gl-link target="_blank" :href="link.url">
          <span class="text-truncate">{{ link.text }}</span>
          <gl-icon name="external-link" class="gl-ml-2 gl-flex-shrink-0 gl-text-black-normal" />
        </gl-link>
      </slot>
    </p>
  </div>
</template>
