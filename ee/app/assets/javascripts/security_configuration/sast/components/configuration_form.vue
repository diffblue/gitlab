<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { cloneDeep } from 'lodash';
import DynamicFields from 'ee/security_configuration/components/dynamic_fields.vue';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { __, s__ } from '~/locale';
import configureSastMutation from '~/security_configuration/graphql/configure_sast.mutation.graphql';
import { toSastCiConfigurationEntityInput } from './utils';

export default {
  components: {
    DynamicFields,
    GlAlert,
    GlButton,
  },
  inject: {
    securityConfigurationPath: {
      from: 'securityConfigurationPath',
      default: '',
    },
    projectPath: {
      from: 'projectPath',
      default: '',
    },
  },
  props: {
    // A SastCiConfiguration GraphQL object
    sastCiConfiguration: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      globalConfiguration: cloneDeep(this.sastCiConfiguration.global.nodes),
      pipelineConfiguration: cloneDeep(this.sastCiConfiguration.pipeline.nodes),
      hasSubmissionError: false,
      isSubmitting: false,
    };
  },
  methods: {
    onSubmit() {
      this.isSubmitting = true;
      this.hasSubmissionError = false;

      return this.$apollo
        .mutate({
          mutation: configureSastMutation,
          variables: {
            input: {
              projectPath: this.projectPath,
              configuration: this.getMutationConfiguration(),
            },
          },
        })
        .then(({ data }) => {
          const { errors, successPath } = data.configureSast;

          if (errors.length > 0 || !successPath) {
            // eslint-disable-next-line @gitlab/require-i18n-strings
            throw new Error('SAST merge request creation mutation failed');
          }

          redirectTo(successPath); // eslint-disable-line import/no-deprecated
        })
        .catch((error) => {
          this.isSubmitting = false;
          this.hasSubmissionError = true;
          Sentry.captureException(error);
        });
    },
    getMutationConfiguration() {
      return {
        global: this.globalConfiguration.map(toSastCiConfigurationEntityInput),
        pipeline: this.pipelineConfiguration.map(toSastCiConfigurationEntityInput),
      };
    },
  },
  i18n: {
    submissionError: s__(
      'SecurityConfiguration|An error occurred while creating the merge request.',
    ),
    submitButton: s__('SecurityConfiguration|Create merge request'),
    cancelButton: __('Cancel'),
  },
};
</script>

<template>
  <form @submit.prevent="onSubmit">
    <dynamic-fields v-model="globalConfiguration" class="gl-m-0" />
    <dynamic-fields v-model="pipelineConfiguration" class="gl-m-0" />
    <hr class="gl-mt-3" />
    <gl-alert
      v-if="hasSubmissionError"
      data-testid="analyzers-error-alert"
      class="gl-mb-5"
      variant="danger"
      :dismissible="false"
      >{{ $options.i18n.submissionError }}</gl-alert
    >

    <div class="gl-display-flex">
      <gl-button
        ref="submitButton"
        class="gl-mr-3 js-no-auto-disable"
        :loading="isSubmitting"
        type="submit"
        variant="confirm"
        category="primary"
        data-testid="submit-button"
        >{{ $options.i18n.submitButton }}</gl-button
      >

      <gl-button ref="cancelButton" :href="securityConfigurationPath">{{
        $options.i18n.cancelButton
      }}</gl-button>
    </div>
  </form>
</template>
