<script>
import { PAGE_TITLE, PAGE_SUBTITLE } from '../constants';
import PhoneVerification from './phone_verification.vue';

export default {
  name: 'IdentityVerificationWizard',
  components: {
    PhoneVerification,
  },
  i18n: {
    PAGE_TITLE,
    PAGE_SUBTITLE,
  },
};
</script>
<template>
  <div class="gl--flex-center">
    <div class="gl-max-w-62">
      <header class="gl-text-center">
        <h2>{{ $options.i18n.PAGE_TITLE }}</h2>
        <p>{{ $options.i18n.PAGE_SUBTITLE }}</p>
      </header>
      <phone-verification />
    </div>
  </div>
</template>
