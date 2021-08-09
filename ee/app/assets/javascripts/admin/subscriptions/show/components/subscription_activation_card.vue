<script>
import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { activateSubscription, howToActivateSubscription, uploadLicenseFile } from '../constants';
import SubscriptionActivationErrors from './subscription_activation_errors.vue';
import SubscriptionActivationForm from './subscription_activation_form.vue';

export const activateSubscriptionUrl = helpPagePath('user/admin_area/license.html', {
  anchor: 'activate-gitlab-ee-with-an-activation-code',
});

export default {
  name: 'SubscriptionActivationCard',
  i18n: {
    activateSubscription,
    howToActivateSubscription,
    uploadLicenseFile,
  },
  components: {
    GlCard,
    GlLink,
    GlSprintf,
    SubscriptionActivationErrors,
    SubscriptionActivationForm,
  },
  inject: ['licenseUploadPath'],
  links: {
    activateSubscriptionUrl,
  },
  data() {
    return {
      error: null,
    };
  },
  methods: {
    handleFormActivationFailure(error) {
      this.error = error;
    },
  },
};
</script>

<template>
  <gl-card body-class="gl-p-0">
    <template #header>
      <h5 class="gl-my-0 gl-font-weight-bold">
        {{ $options.i18n.activateSubscription }}
      </h5>
    </template>
    <div v-if="error" class="gl-p-5 gl-border-b-1 gl-border-gray-100 gl-border-b-solid">
      <subscription-activation-errors class="mb-4" :error="error" />
    </div>
    <p class="gl-mb-0 gl-px-5 gl-pt-5">
      <gl-sprintf :message="$options.i18n.howToActivateSubscription">
        <template #link="{ content }">
          <gl-link
            data-testid="activate-subscription-link"
            :href="$options.links.activateSubscriptionUrl"
            target="_blank"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </p>
    <subscription-activation-form
      class="gl-p-5"
      @subscription-activation-failure="handleFormActivationFailure"
    />
    <template #footer>
      <gl-link
        v-if="licenseUploadPath"
        data-testid="upload-license-link"
        data-qa-selector="license_upload_link"
        :href="licenseUploadPath"
        >{{ $options.i18n.uploadLicenseFile }}
      </gl-link>
    </template>
  </gl-card>
</template>
