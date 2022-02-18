<script>
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  inject: ['exitPath'],
  data() {
    return {
      showLink: true,
      disabled: false,
    };
  },
  created() {
    eventHub.$on('verificationCompleted', this.toggleLink);
  },
  beforeDestroy() {
    eventHub.$off('verificationCompleted', this.toggleLink);
  },
  methods: {
    toggleLink() {
      this.showLink = false;
    },
    disableLink() {
      this.disabled = true;
    },
  },
  i18n: {
    link: __('Exit.'),
    explanation: s__(
      'IdentityVerification|You can always verify your account at a later time to create a group.',
    ),
  },
};
</script>
<template>
  <div v-if="showLink" class="gl-text-center">
    <div class="gl-pt-6 gl-pb-3">
      <gl-button
        data-testid="exit-link"
        variant="link"
        :disabled="disabled"
        :aria-label="$options.i18n.link"
        :href="exitPath"
        data-method="put"
        rel="nofollow"
        @click="disableLink"
      >
        {{ $options.i18n.link }}
      </gl-button>
    </div>
    <div class="gl-text-secondary gl-font-sm">
      {{ $options.i18n.explanation }}
    </div>
  </div>
</template>
