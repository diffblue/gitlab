<script>
import { GlForm, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import InternationalPhoneInput from './international_phone_input.vue';

export default {
  name: 'PhoneVerification',
  components: {
    GlForm,
    GlButton,
    InternationalPhoneInput,
  },
  i18n: {
    sendCode: s__('IdentityVerification|Send code'),
  },
};
</script>
<template>
  <gl-form>
    <international-phone-input />

    <gl-button variant="confirm" type="submit" class="gl-w-full! gl-mt-5">
      {{ $options.i18n.sendCode }}
    </gl-button>
  </gl-form>
</template>
