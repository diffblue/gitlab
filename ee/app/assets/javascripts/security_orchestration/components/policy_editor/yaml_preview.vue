<script>
import { GlAlert } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { PARSING_ERROR_MESSAGE } from './constants';

export default {
  i18n: {
    PARSING_ERROR_MESSAGE,
  },
  components: {
    GlAlert,
  },
  directives: {
    SafeHtml,
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
