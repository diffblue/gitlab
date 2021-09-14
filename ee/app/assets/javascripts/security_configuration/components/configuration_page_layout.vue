<script>
import { GlAlert } from '@gitlab/ui';

export default {
  components: {
    GlAlert,
  },
  data() {
    return { isAlertDismissed: false };
  },
  computed: {
    showPageAlert() {
      return Boolean(this.$slots.alert) && !this.isAlertDismissed;
    },
  },
};
</script>

<template>
  <article>
    <gl-alert
      v-if="showPageAlert"
      data-testid="configuration-page-alert"
      class="gl-mt-4"
      @dismiss="isAlertDismissed = true"
    >
      <slot name="alert"></slot
    ></gl-alert>

    <header class="gl-my-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid">
      <h4>
        <slot name="heading"></slot>
      </h4>
      <p>
        <slot name="description"></slot>
      </p>
    </header>

    <slot></slot>
  </article>
</template>
