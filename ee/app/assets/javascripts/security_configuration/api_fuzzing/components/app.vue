<script>
import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ConfigurationPageLayout from '../../components/configuration_page_layout.vue';
import apiFuzzingCiConfigurationQuery from '../graphql/api_fuzzing_ci_configuration.query.graphql';
import ConfigurationForm from './configuration_form.vue';

export default {
  components: {
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    ConfigurationForm,
    ConfigurationPageLayout,
  },
  inject: {
    fullPath: {
      from: 'fullPath',
    },
    apiFuzzingDocumentationPath: {
      from: 'apiFuzzingDocumentationPath',
    },
  },
  apollo: {
    apiFuzzingCiConfiguration: {
      query: apiFuzzingCiConfigurationQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ project: { apiFuzzingCiConfiguration } }) {
        return apiFuzzingCiConfiguration;
      },
    },
  },
  i18n: {
    title: s__('APIFuzzing|API Fuzzing Configuration'),
    helpText: s__(
      `APIFuzzing|Customize your project's API fuzzing configuration options and copy the code snippet to your .gitlab-ci.yml file to apply any changes. Note that this tool does not reflect or update your .gitlab-ci.yml file automatically. For details of more advanced configuration options, see the %{docsLinkStart}GitLab API Fuzzing documentation%{docsLinkEnd}.`,
    ),
  },
};
</script>

<template>
  <configuration-page-layout>
    <template #heading> {{ $options.i18n.title }} </template>
    <template #description>
      <gl-sprintf :message="$options.i18n.helpText">
        <template #docsLink="{ content }">
          <gl-link :href="apiFuzzingDocumentationPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>

    <gl-loading-icon v-if="$apollo.loading" size="lg" />

    <configuration-form v-else :api-fuzzing-ci-configuration="apiFuzzingCiConfiguration" />
  </configuration-page-layout>
</template>
