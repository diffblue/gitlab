<script>
import { GlLoadingIcon, GlLink, GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AnalyticsClipboardInput from '../shared/analytics_clipboard_input.vue';
import getProjectTrackingKeyQuery from '../graphql/queries/get_project_tracking_key.query.graphql';
import OnboardingSetupCollapse from './components/onboarding_setup_collapse.vue';

import {
  INSTALL_NPM_PACKAGE,
  ESM_SETUP_WITH_NPM,
  COMMON_JS_SETUP_WITH_NPM,
  HTML_SCRIPT_SETUP,
} from './constants';

export default {
  name: 'ProductAnalyticsOnboardingSetup',
  components: {
    GlLoadingIcon,
    AnalyticsClipboardInput,
    OnboardingSetupCollapse,
    GlLink,
    GlButton,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    collectorHost: {
      type: String,
    },
    trackingKey: {
      type: String,
    },
    projectFullPath: {
      type: String,
    },
  },
  props: {
    isInitialSetup: {
      type: Boolean,
      required: false,
      default: false,
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
    instructions() {
      return {
        install: this.replaceKeys(INSTALL_NPM_PACKAGE),
        esmSetup: this.replaceKeys(ESM_SETUP_WITH_NPM),
        commonJsSetup: this.replaceKeys(COMMON_JS_SETUP_WITH_NPM),
        htmlSetup: this.replaceKeys(HTML_SCRIPT_SETUP),
      };
    },
  },
  apollo: {
    apolloTrackingKey: {
      query: getProjectTrackingKeyQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
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
  methods: {
    replaceKeys(template) {
      const hostKey = '$host';
      const appIdValuePlaceholder = '$applicationId';
      const appIdPropertyNamePlaceholder = '$appIdProperty';
      const appIdPropertyName = this.glFeatures.productAnalyticsSnowplowSupport
        ? 'appId'
        : 'applicationId';
      const packageVersionPlaceholder = '$version';

      // 0.0.5 is the last version supported by Jitsu. Everything after that is Snowplow.
      const packageVersion = this.glFeatures.productAnalyticsSnowplowSupport ? '' : '@0.0.5';

      return template
        .replace(hostKey, this.collectorHost)
        .replace(appIdValuePlaceholder, this.appIdKey)
        .replace(appIdPropertyNamePlaceholder, appIdPropertyName)
        .replaceAll(packageVersionPlaceholder, packageVersion);
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
    sdkHost: s__('ProductAnalytics|SDK Host'),
    sdkHostDescription: s__('ProductAnalytics|The host to send all tracking events to'),
    sdkAppId: s__('ProductAnalytics|SDK App ID'),
    sdkAppIdDescription: s__('ProductAnalytics|Identifies the sender of tracking events'),
    esmModule: __('ESM module'),
    esmModuleDescription: s__('ProductAnalytics|Steps to add product analytics as an ESM module'),
    commonJsModule: __('CommonJS module'),
    commonJsModuleDescription: s__(
      'ProductAnalytics|Steps to add product analytics as a CommonJS module',
    ),
    htmlScriptTag: __('HTML script tag'),
    htmlScriptTagDescription: s__(
      'ProductAnalytics|Steps to add product analytics as a HTML script tag',
    ),
    addNpmPackage: s__(
      'ProductAnalytics|Add the NPM package to your package.json using your preferred package manager:',
    ),
    importNpmPackage: s__('ProductAnalytics|Import the new package into your JS code:'),
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

    <section class="gl-display-flex gl-flex-wrap gl-mb-6">
      <analytics-clipboard-input
        class="gl-mr-6 gl-mb-6 gl-md-mb-0"
        :label="$options.i18n.sdkHost"
        :description="$options.i18n.sdkHostDescription"
        :value="collectorHost"
      />

      <analytics-clipboard-input
        :label="$options.i18n.sdkAppId"
        :description="$options.i18n.sdkAppIdDescription"
        :value="appIdKey"
      />
    </section>

    <onboarding-setup-collapse
      :label="$options.i18n.esmModule"
      :description="$options.i18n.esmModuleDescription"
      visible
    >
      <h5>{{ $options.i18n.addNpmPackage }}</h5>
      <pre>{{ instructions.install }}</pre>
      <h5>{{ $options.i18n.importNpmPackage }}</h5>
      <pre>{{ instructions.esmSetup }}</pre>
    </onboarding-setup-collapse>

    <onboarding-setup-collapse
      :label="$options.i18n.commonJsModule"
      :description="$options.i18n.commonJsModuleDescription"
    >
      <h5>{{ $options.i18n.addNpmPackage }}</h5>
      <pre>{{ instructions.install }}</pre>
      <h5>{{ $options.i18n.importNpmPackage }}</h5>
      <pre>{{ instructions.commonJsSetup }}</pre>
    </onboarding-setup-collapse>

    <onboarding-setup-collapse
      :label="$options.i18n.htmlScriptTag"
      :description="$options.i18n.htmlScriptTagDescription"
    >
      <h5>{{ $options.i18n.addHtmlScriptToPage }}</h5>
      <pre>{{ instructions.htmlSetup }}</pre>
    </onboarding-setup-collapse>
  </section>
</template>
