<script>
import { GlButton, GlPopover, GlLink, GlIcon } from '@gitlab/ui';
import Tracking from '~/tracking';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import Zuora from 'ee/billings/components/zuora.vue';
import {
  I18N,
  IFRAME_MINIMUM_HEIGHT,
  EVENT_LABEL,
  MOUNTED_EVENT,
  SKIPPED_EVENT,
  VERIFIED_EVENT,
} from '../constants';

export default {
  components: {
    GlButton,
    GlPopover,
    GlLink,
    GlIcon,
    Zuora,
  },
  mixins: [Tracking.mixin({ label: EVENT_LABEL })],
  inject: ['nextStepUrl'],
  data() {
    return {
      isSkipConfirmationVisible: false,
      isSkipConfirmationDismissed: false,
      iframeUrl: gon.registration_validation_form_url,
      allowedOrigin: gon.subscriptions_url,
    };
  },
  mounted() {
    this.track(MOUNTED_EVENT);
  },
  methods: {
    submit() {
      this.$refs.zuora.submit();
    },
    handleSkip() {
      if (this.isSkipConfirmationDismissed) {
        this.skip();
      } else {
        this.isSkipConfirmationVisible = true;
      }
    },
    dismissSkipConfirmation() {
      this.isSkipConfirmationVisible = false;
      this.isSkipConfirmationDismissed = true;
    },
    skip() {
      this.track(SKIPPED_EVENT);
      this.nextStep();
    },
    verified() {
      this.track(VERIFIED_EVENT);
      this.nextStep();
    },
    nextStep() {
      redirectTo(this.nextStepUrl); // eslint-disable-line import/no-deprecated
    },
  },
  i18n: I18N,
  iframeHeight: IFRAME_MINIMUM_HEIGHT,
};
</script>

<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-px-5 gl-text-center"
  >
    <div class="verify-identity gl-display-flex gl-flex-direction-column gl-align-items-center">
      <h2>
        {{ $options.i18n.title }}
      </h2>
      <p>
        {{ $options.i18n.description }}
      </p>
      <div
        class="gl-border-gray-50 gl-border-solid gl-border-1 gl-rounded-base gl-w-85p gl-xs-w-full gl-px-4 gl-pt-3 gl-pb-4 gl-text-left"
      >
        <zuora
          ref="zuora"
          :initial-height="$options.iframeHeight"
          :iframe-url="iframeUrl"
          :allowed-origin="allowedOrigin"
          @success="verified"
        />
        <div class="gl-display-flex gl-mx-5 gl-mb-5">
          <gl-icon name="information-o" :size="12" class="gl-mt-1" />
          <div class="gl-ml-3 gl-text-secondary gl-font-sm">
            {{ $options.i18n.disclaimer }}
          </div>
        </div>
        <gl-button
          ref="submitButton"
          variant="confirm"
          type="submit"
          class="gl-w-full!"
          @click="submit"
        >
          {{ $options.i18n.submit }}
        </gl-button>
      </div>
    </div>
    <div class="gl-mt-6 gl-md-mt-11!">
      <gl-button ref="skipLink" variant="link" @click="handleSkip">
        {{ $options.i18n.skip }}
      </gl-button>
      <gl-popover
        v-if="isSkipConfirmationVisible"
        ref="popover"
        show
        triggers="manual blur"
        placement="top"
        :target="$refs.skipLink"
        @hide="dismissSkipConfirmation"
      >
        <template #title>
          <div class="gl-display-flex gl-align-items-center">
            <div class="gl-white-space-nowrap">{{ $options.i18n.skip_confirmation.title }}</div>
            <gl-button
              ref="popoverClose"
              category="tertiary"
              class="gl-opacity-10"
              icon="close"
              :aria-label="__('Close')"
              @click="dismissSkipConfirmation"
            />
          </div>
        </template>
        {{ $options.i18n.skip_confirmation.content }}
        <div class="gl-text-right gl-mt-4">
          <gl-link ref="skipConfirmationLink" @click="skip">
            {{ $options.i18n.skip_confirmation.link }}
          </gl-link>
        </div>
      </gl-popover>
      <div class="gl-text-secondary gl-font-sm gl-mt-2">
        {{ $options.i18n.skip_explanation }}
      </div>
    </div>
  </div>
</template>
