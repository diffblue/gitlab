<script>
import {
  SBOM_BANNER_LOCAL_STORAGE_KEY,
  SBOM_BANNER_CURRENT_ID,
  SBOM_SURVEY_LINK,
  SBOM_SURVEY_DAYS_TO_ASK_LATER,
  SBOM_SURVEY_TITLE,
  SBOM_SURVEY_BUTTON_TEXT,
  SBOM_SURVEY_DESCRIPTION,
  SBOM_SURVEY_TOAST_MESSAGE,
} from 'ee/vue_shared/constants';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SurveyBanner from 'ee/vue_shared/survey_banner/survey_banner.vue';

export default {
  name: 'SbomBanner',
  components: {
    SurveyBanner,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    sbomSurveySvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    shouldShowSbomSurvey() {
      return this.glFeatures.sbomSurvey;
    },
  },
  storageKey: SBOM_BANNER_LOCAL_STORAGE_KEY,
  bannerId: SBOM_BANNER_CURRENT_ID,
  surveyLink: SBOM_SURVEY_LINK,
  daysToAskLater: SBOM_SURVEY_DAYS_TO_ASK_LATER,
  title: SBOM_SURVEY_TITLE,
  buttonText: SBOM_SURVEY_BUTTON_TEXT,
  description: SBOM_SURVEY_DESCRIPTION,
  toastMessage: SBOM_SURVEY_TOAST_MESSAGE,
};
</script>

<template>
  <survey-banner
    v-if="shouldShowSbomSurvey"
    :svg-path="sbomSurveySvgPath"
    :survey-link="$options.surveyLink"
    :days-to-ask-later="$options.daysToAskLater"
    :title="$options.title"
    :button-text="$options.buttonText"
    :description="$options.description"
    :toast-message="$options.toastMessage"
    :storage-key="$options.storageKey"
    :banner-id="$options.bannerId"
    class="gl-mt-5"
  />
</template>
