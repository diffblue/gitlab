<script>
import { GlAlert, GlSafeHtmlDirective } from '@gitlab/ui';
import { PARSING_ERROR_MESSAGE } from './constants';

export default {
  i18n: {
    PARSING_ERROR_MESSAGE,
  },
  components: {
    GlAlert,
  },
  directives: {
    safeHtml: GlSafeHtmlDirective,
  },
  props: {
    policyDescription: {
      type: String,
      required: false,
      default: '',
    },
  },
  safeHtmlConfig: { ALLOWED_TAGS: ['strong', 'br'] },
};
</script>

<template>
  <div v-if="policyDescription" v-safe-html:[$options.safeHtmlConfig]="policyDescription"></div>
  <div v-else>
    <gl-alert variant="info" :dismissible="false">
      {{ $options.i18n.PARSING_ERROR_MESSAGE }}
    </gl-alert>
  </div>
</template>
