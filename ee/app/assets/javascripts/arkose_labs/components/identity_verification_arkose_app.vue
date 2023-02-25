<script>
import { GlForm, GlLoadingIcon } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { initArkoseLabsScript } from '../init_arkose_labs_script';
import { VERIFICATION_TOKEN_INPUT_NAME, CHALLENGE_CONTAINER_CLASS } from '../constants';

export default {
  csrf,
  components: { GlForm, GlLoadingIcon },
  props: {
    publicKey: {
      type: String,
      required: true,
    },
    domain: {
      type: String,
      required: true,
    },
    sessionVerificationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      arkoseLabsIframeShown: false,
      arkoseToken: '',
    };
  },
  mounted() {
    this.initArkoseLabs();
  },
  methods: {
    onArkoseLabsIframeShown() {
      this.arkoseLabsIframeShown = true;
    },
    async initArkoseLabs() {
      const arkoseObject = await initArkoseLabsScript({
        publicKey: this.publicKey,
        domain: this.domain,
      });

      arkoseObject.setConfig({
        mode: 'inline',
        selector: `.${this.$options.CHALLENGE_CONTAINER_CLASS}`,
        onShown: this.onArkoseLabsIframeShown,
        onCompleted: this.passArkoseLabsChallenge,
      });
    },
    passArkoseLabsChallenge({ token }) {
      this.arkoseToken = token;

      this.$nextTick(() => {
        this.$refs.form.$el.submit();
      });
    },
  },
  VERIFICATION_TOKEN_INPUT_NAME,
  CHALLENGE_CONTAINER_CLASS,
};
</script>

<template>
  <gl-form
    ref="form"
    :action="sessionVerificationPath"
    method="post"
    data-testid="arkose-labs-token-form"
  >
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <input
      :name="$options.VERIFICATION_TOKEN_INPUT_NAME"
      type="hidden"
      :value="arkoseToken"
      data-testid="arkose-labs-token-input"
    />
    <div
      class="gl-display-flex gl-justify-content-center"
      :class="$options.CHALLENGE_CONTAINER_CLASS"
    >
      <gl-loading-icon v-if="!arkoseLabsIframeShown" size="lg" class="gl-my-4" />
    </div>
  </gl-form>
</template>
