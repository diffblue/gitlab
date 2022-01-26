<script>
import { GlBreadcrumb, GlButton, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import newGroupIllustration from '@gitlab/svgs/dist/illustrations/group-new.svg';
import CreateGroupDescriptionDetails from '~/pages/groups/new/components/create_group_description_details.vue';
import Zuora from 'ee/billings/components/zuora.vue';
import {
  I18N_FORM_EXPLANATION,
  I18N_FORM_SUBMIT,
  I18N_FORM_TITLE,
  I18N_SIDE_PANE_TITLE,
} from '../constants';

export default {
  components: {
    GlBreadcrumb,
    GlButton,
    CreateGroupDescriptionDetails,
    Zuora,
  },
  directives: {
    SafeHtml,
  },
  inject: ['verificationFormUrl', 'subscriptionsUrl'],
  data() {
    return {
      iframeUrl: this.verificationFormUrl,
      allowedOrigin: this.subscriptionsUrl,
      isLoading: true,
    };
  },
  methods: {
    updateIsLoading(isLoading) {
      this.isLoading = isLoading;
    },
    verified() {
      this.$emit('verified');
    },
    submit() {
      this.$refs.zuora.submit();
    },
  },
  illustration: newGroupIllustration,
  I18N_SIDE_PANE_TITLE,
  I18N_FORM_TITLE,
  I18N_FORM_EXPLANATION,
  I18N_FORM_SUBMIT,
};
</script>
<template>
  <div class="row">
    <div class="col-lg-3">
      <div v-safe-html="$options.illustration" class="gl-text-white"></div>
      <h4>{{ $options.I18N_SIDE_PANE_TITLE }}</h4>
      <create-group-description-details />
    </div>
    <div class="col-lg-9">
      <gl-breadcrumb :items="[]" />
      <label class="gl-mt-3">{{ $options.I18N_FORM_TITLE }}</label>
      <p>{{ $options.I18N_FORM_EXPLANATION }}</p>
      <zuora
        ref="zuora"
        :initial-height="328"
        :iframe-url="iframeUrl"
        :allowed-origin="allowedOrigin"
        @success="verified"
        @loading="updateIsLoading"
      />
      <gl-button variant="confirm" type="submit" :disabled="isLoading" @click="submit">{{
        $options.I18N_FORM_SUBMIT
      }}</gl-button>
    </div>
  </div>
</template>
