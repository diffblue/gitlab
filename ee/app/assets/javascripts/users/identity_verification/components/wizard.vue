<script>
import { PAGE_TITLE } from '../constants';
import EmailVerification from './email_verification.vue';

export default {
  name: 'IdentityVerificationWizard',
  components: {
    EmailVerification,
  },
  i18n: {
    PAGE_TITLE,
  },
};
</script>
<template>
  <div class="gl--flex-center">
    <div class="gl-max-w-62">
      <header class="gl-text-center">
        <h2>{{ $options.i18n.PAGE_TITLE }}</h2>
      </header>
      <email-verification />
    </div>
  </div>
</template>
