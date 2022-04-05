<script>
import { GlButton, GlBanner, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import showToast from '~/vue_shared/plugins/global_toast';

export default {
  components: { GlButton, GlBanner, GlSprintf, LocalStorageSync },
  props: {
    surveyLink: {
      type: String,
      required: true,
    },
    daysToAskLater: {
      type: Number,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    buttonText: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    toastMessage: {
      type: String,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
    },
    bannerId: {
      type: String,
      required: true,
    },
    svgPath: {
      type: String,
      required: true,
    },
  },
  data: () => ({
    surveyShowDate: null,
  }),
  computed: {
    shouldShowSurvey() {
      const { surveyShowDate } = this;
      const date = new Date(surveyShowDate);

      // Survey is not enabled or user dismissed the survey by clicking the close icon.
      if (surveyShowDate === this.$props.bannerId) {
        return false;
      }
      // Date is invalid, we should show the survey.
      else if (Number.isNaN(date.getDate())) {
        return true;
      }

      return date <= Date.now();
    },
  },
  methods: {
    hideSurvey() {
      this.surveyShowDate = this.$props.bannerId;
    },
    askLater() {
      const date = new Date();
      date.setDate(date.getDate() + this.daysToAskLater);
      this.surveyShowDate = date.toISOString();

      showToast(this.$props.toastMessage);
    },
  },
  i18n: {
    askAgainLater: __('Ask again later'),
  },
};
</script>

<template>
  <local-storage-sync v-model="surveyShowDate" :storage-key="storageKey" as-string>
    <gl-banner
      v-if="shouldShowSurvey"
      :title="title"
      :button-text="buttonText"
      :svg-path="svgPath"
      :button-link="surveyLink"
      @close="hideSurvey"
    >
      <p>
        <gl-sprintf :message="description">
          <template #bold="{ content }">
            <span class="gl-font-weight-bold">{{ content }}</span>
          </template>
        </gl-sprintf>
      </p>

      <template #actions>
        <gl-button variant="link" class="gl-ml-5" data-testid="ask-later-button" @click="askLater">
          {{ $options.i18n.askAgainLater }}
        </gl-button>
      </template>
    </gl-banner>
  </local-storage-sync>
</template>
