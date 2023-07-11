<script>
import { GlButton, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import getProjectTrackingKeyQuery from '../graphql/queries/get_project_tracking_key.query.graphql';
import InstrumentationInstructions from './components/instrumentation_instructions.vue';

export default {
  name: 'ProductAnalyticsOnboardingSetup',
  components: {
    GlLoadingIcon,
    GlLink,
    GlButton,
    InstrumentationInstructions,
  },
  inject: {
    collectorHost: {
      type: String,
    },
    trackingKey: {
      type: String,
    },
    namespaceFullPath: {
      type: String,
    },
  },
  props: {
    isInitialSetup: {
      type: Boolean,
      required: false,
      default: false,
    },
    dashboardsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      apolloTrackingKey: null,
    };
  },
  computed: {
    appIdKey() {
      return this.trackingKey ?? this.apolloTrackingKey;
    },
    description() {
      if (this.isInitialSetup) {
        return this.$options.i18n.initialSetupDescription;
      }
      return this.$options.i18n.description;
    },
  },
  apollo: {
    apolloTrackingKey: {
      query: getProjectTrackingKeyQuery,
      variables() {
        return {
          projectPath: this.namespaceFullPath,
        };
      },
      update(data) {
        return data?.project?.trackingKey;
      },
      skip() {
        return this.appIdKey;
      },
      error(err) {
        this.$emit('error', err);
      },
    },
  },
  i18n: {
    title: s__('ProductAnalytics|Instrument your application'),
    description: s__(
      'ProductAnalytics|Details on how to configure product analytics to collect data.',
    ),
    initialSetupDescription: s__(
      'ProductAnalytics|For the product analytics dashboard to start showing you some data, you need to add the analytics tracking code to your project.',
    ),
    introduction: s__(
      'ProductAnalytics|To instrument your application, select one of the options below. After an option has been instrumented and data is being collected, this page will progress to the next step.',
    ),
    learnMore: __('Learn more.'),

    backToDashboards: s__('ProductAnalytics|Back to dashboards'),
    addHtmlScriptToPage: s__(
      'ProductAnalytics|Add the script to the page and assign the client SDK to window:',
    ),
  },
  docsPath: helpPagePath('user/product_analytics/index'),
};
</script>

<template>
  <gl-loading-icon v-if="!appIdKey" size="lg" class="gl-my-7" />

  <section v-else>
    <header class="gl-display-flex gl-justify-content-space-between gl-align-items-flex-start">
      <div class="gl-mb-7">
        <h2 class="gl-mb-4" data-testid="title">{{ $options.i18n.title }}</h2>
        <p class="gl-mb-0" data-testid="description">
          {{ description }}
          <gl-link data-testid="help-link" :href="$options.docsPath">
            {{ $options.i18n.learnMore }}
          </gl-link>
        </p>
      </div>
      <gl-button
        v-if="!isInitialSetup"
        class="gl-my-6"
        to="/"
        data-testid="back-to-dashboards-button"
      >
        {{ $options.i18n.backToDashboards }}
      </gl-button>
    </header>

    <p v-if="isInitialSetup" class="gl-mb-6" data-testid="introduction">
      {{ $options.i18n.introduction }}
    </p>

    <instrumentation-instructions :tracking-key="appIdKey" :dashboards-path="dashboardsPath" />
  </section>
</template>
