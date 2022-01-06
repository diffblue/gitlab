<script>
import {
  SURVEY_BANNER_LOCAL_STORAGE_KEY,
  SURVEY_BANNER_CURRENT_ID,
  SURVEY_LINK,
  SURVEY_DAYS_TO_ASK_LATER,
  SURVEY_TITLE,
  SURVEY_TOAST_MESSAGE,
  SURVEY_BUTTON_TEXT,
  SURVEY_DESCRIPTION,
} from 'ee/security_dashboard/constants';

import SurveyBanner from 'ee/vue_shared/survey_banner/survey_banner.vue';

export default {
  name: 'VulnManagementFeatureSurvey',
  components: {
    SurveyBanner,
  },
  inject: ['surveyRequestSvgPath'],

  storageKey: SURVEY_BANNER_LOCAL_STORAGE_KEY,
  surveyLink: SURVEY_LINK,
  daysToAskLater: SURVEY_DAYS_TO_ASK_LATER,
  bannerId: SURVEY_BANNER_CURRENT_ID,
  title: SURVEY_TITLE,
  toastMessage: SURVEY_TOAST_MESSAGE,
  buttonText: SURVEY_BUTTON_TEXT,
  description: SURVEY_DESCRIPTION,
};
</script>

<template>
  <survey-banner
    :svg-path="surveyRequestSvgPath"
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
