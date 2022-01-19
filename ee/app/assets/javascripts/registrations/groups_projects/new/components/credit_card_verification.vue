<script>
import { GlButton } from '@gitlab/ui';
import Zuora from 'ee/billings/components/zuora.vue';
import { I18N, IFRAME_MINIMUM_HEIGHT } from '../constants';
import StaticToggle from './static_toggle.vue';

export default {
  components: {
    GlButton,
    StaticToggle,
    Zuora,
  },
  inject: ['completed', 'iframeUrl', 'allowedOrigin'],
  data() {
    return {
      verificationCompleted: this.completed,
    };
  },
  watch: {
    verificationCompleted() {
      this.toggleProjectCreation();
    },
  },
  mounted() {
    this.toggleProjectCreation();
  },
  methods: {
    submit() {
      this.$refs.zuora.submit();
    },
    verified() {
      this.verificationCompleted = true;
    },
    toggleProjectCreation() {
      // Workaround until we refactor group and project creation into Vue
      // https://gitlab.com/gitlab-org/gitlab/-/issues/339998
      const el = document.querySelector('.js-toggle-container');
      el.classList.toggle('gl-display-none', !this.verificationCompleted);
    },
  },
  i18n: I18N,
  iframeHeight: IFRAME_MINIMUM_HEIGHT,
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-w-full">
    <static-toggle
      ref="verifyToggle"
      :enabled="!verificationCompleted"
      :completed="verificationCompleted"
      :title="$options.i18n.verifyToggle"
    />
    <div
      v-if="!verificationCompleted"
      class="gl-border-gray-100 gl-border-solid gl-border-1 gl-rounded-base gl-px-2 gl-py-5 gl-text-left"
    >
      <div class="gl-px-4 gl-text-secondary gl-font-sm">
        {{ $options.i18n.explanation }}
      </div>
      <zuora
        ref="zuora"
        :initial-height="$options.iframeHeight"
        :iframe-url="iframeUrl"
        :allowed-origin="allowedOrigin"
        @success="verified"
      />
      <div class="gl-px-4">
        <gl-button
          ref="submitButton"
          variant="confirm"
          type="submit"
          class="gl-w-full!"
          @click="submit"
        >
          {{ $options.i18n.submitVerify }}
        </gl-button>
      </div>
    </div>
    <static-toggle
      ref="createToggle"
      :enabled="verificationCompleted"
      :title="$options.i18n.createToggle"
    />
  </div>
</template>
