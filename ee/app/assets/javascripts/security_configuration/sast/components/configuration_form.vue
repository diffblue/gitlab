<script>
import { GlAlert, GlButton, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { cloneDeep } from 'lodash';
import DynamicFields from 'ee/security_configuration/components/dynamic_fields.vue';
import ExpandableSection from 'ee/security_configuration/components/expandable_section.vue';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { __, s__ } from '~/locale';
import configureSastMutation from '~/security_configuration/graphql/configure_sast.mutation.graphql';
import AnalyzerConfiguration from './analyzer_configuration.vue';
import {
  toSastCiConfigurationEntityInput,
  toSastCiConfigurationAnalyzerEntityInput,
} from './utils';

export default {
  components: {
    AnalyzerConfiguration,
    DynamicFields,
    ExpandableSection,
    GlAlert,
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  inject: {
    sastAnalyzersDocumentationPath: {
      from: 'sastAnalyzersDocumentationPath',
      default: '',
    },
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
      analyzersConfiguration: cloneDeep(this.sastCiConfiguration.analyzers.nodes),
      hasSubmissionError: false,
      isSubmitting: false,
    };
  },
  computed: {
    shouldRenderAnalyzersSection() {
      return this.analyzersConfiguration.length > 0;
    },
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
        analyzers: this.analyzersConfiguration.map(toSastCiConfigurationAnalyzerEntityInput),
      };
    },
    onAnalyzerChange(name, updatedAnalyzer) {
      const index = this.analyzersConfiguration.findIndex((analyzer) => analyzer.name === name);
      if (index === -1) {
        return;
      }

      this.analyzersConfiguration.splice(index, 1, updatedAnalyzer);
    },
  },
  i18n: {
    submissionError: s__(
      'SecurityConfiguration|An error occurred while creating the merge request.',
    ),
    submitButton: s__('SecurityConfiguration|Create merge request'),
    cancelButton: __('Cancel'),
    help: __('Help'),
    analyzersHeading: s__('SecurityConfiguration|SAST Analyzers'),
    analyzersSubHeading: s__(
      `SecurityConfiguration|By default, all analyzers are applied in order to
      cover all languages across your project, and only run if the language is
      detected in the merge request.`,
    ),
    analyzersTipHeading: __('We recommend leaving all SAST analyzers enabled'),
    analyzersTipBody: __(
      'Keeping all SAST analyzers enabled future-proofs the project in case new languages are added later on. Determining which analyzers apply is a process that consumes minimal resources and adds minimal time to the pipeline. Leaving all SAST analyzers enabled ensures maximum coverage.',
    ),
  },
};
</script>

<template>
  <form @submit.prevent="onSubmit">
    <dynamic-fields v-model="globalConfiguration" class="gl-m-0" />
    <dynamic-fields v-model="pipelineConfiguration" class="gl-m-0" />

    <expandable-section
      v-if="shouldRenderAnalyzersSection"
      class="gl-mb-5"
      data-testid="analyzers-section"
      data-qa-selector="analyzer_settings_content"
    >
      <gl-alert
        class="gl-mb-5"
        data-testid="analyzers-section-tip"
        :title="$options.i18n.analyzersTipHeading"
        variant="tip"
        :dismissible="false"
      >
        <gl-sprintf :message="$options.i18n.analyzersTipBody" />
      </gl-alert>
      <template #heading>
        {{ $options.i18n.analyzersHeading }}
        <gl-link
          target="_blank"
          :href="sastAnalyzersDocumentationPath"
          :aria-label="$options.i18n.help"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </template>

      <template #sub-heading>
        {{ $options.i18n.analyzersSubHeading }}
      </template>

      <analyzer-configuration
        v-for="analyzer in analyzersConfiguration"
        :key="analyzer.name"
        :entity="analyzer"
        @input="onAnalyzerChange(analyzer.name, $event)"
      />
    </expandable-section>

    <hr v-else />

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
        data-qa-selector="submit_button"
        >{{ $options.i18n.submitButton }}</gl-button
      >

      <gl-button ref="cancelButton" :href="securityConfigurationPath">{{
        $options.i18n.cancelButton
      }}</gl-button>
    </div>
  </form>
</template>
