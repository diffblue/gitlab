<script>
import { GlCard, GlForm, GlButton } from '@gitlab/ui';

import { STEP_1_TITLE, SEND_CODE } from '../constants';
import InternationalPhoneInput from './international_phone_input.vue';

export default {
  name: 'PhoneVerification',
  components: {
    GlCard,
    GlForm,
    GlButton,
    InternationalPhoneInput,
  },
  i18n: {
    STEP_1_TITLE,
    SEND_CODE,
  },
};
</script>
<template>
  <gl-card header-class="gl-bg-white gl-border-b-0 gl-pb-0">
    <template #header>
      <h3 class="gl-font-base gl-mt-2 gl-pb-5 gl-border-1 gl-border-b-solid gl-border-gray-100">
        {{ $options.i18n.STEP_1_TITLE }}
      </h3>
    </template>

    <gl-form>
      <international-phone-input />

      <gl-button variant="confirm" type="submit" class="gl-w-full! gl-mt-5">
        {{ $options.i18n.SEND_CODE }}
      </gl-button>
    </gl-form>
  </gl-card>
</template>
