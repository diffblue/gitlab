<script>
import { s__ } from '~/locale';
import SurveyRequestBanner from './survey_request_banner.vue';

export default {
  components: { SurveyRequestBanner },
  i18n: {
    title: s__('SecurityReports|Security Dashboard'),
  },
};
</script>

<template>
  <div>
    <slot name="loading"></slot>
    <survey-request-banner v-if="!$slots.loading" class="gl-mt-5" />

    <template v-if="$slots.default">
      <h2 data-testid="title">{{ $options.i18n.title }}</h2>
      <div class="security-charts gl-display-flex gl-flex-wrap">
        <slot></slot>
      </div>
    </template>

    <slot name="empty-state"></slot>
  </div>
</template>
