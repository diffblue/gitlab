<script>
import { s__ } from '~/locale';
import SbomBanner from 'ee/sbom_banner/components/app.vue';
import SurveyRequestBanner from './survey_request_banner.vue';

export default {
  components: { SurveyRequestBanner, SbomBanner },
  i18n: {
    title: s__('SecurityReports|Security Dashboard'),
  },
  inject: ['sbomSurveySvgPath'],
  props: {
    // this prop is needed since the sbom survey banner should not be shown
    // on the instance security dashboard
    showSbomSurvey: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div>
    <slot name="loading"></slot>
    <survey-request-banner v-if="!$slots.loading" class="gl-mt-5" />
    <sbom-banner
      v-if="!$slots.loading && showSbomSurvey"
      :sbom-survey-svg-path="sbomSurveySvgPath"
    />
    <template v-if="$slots.default">
      <h2 data-testid="title">{{ $options.i18n.title }}</h2>
      <div class="security-charts gl-display-flex gl-flex-wrap">
        <slot></slot>
      </div>
    </template>

    <slot name="empty-state"></slot>
  </div>
</template>
