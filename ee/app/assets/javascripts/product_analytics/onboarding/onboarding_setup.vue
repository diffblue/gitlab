<script>
import { GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import OnboardingKeyInput from './components/onboarding_key_input.vue';
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
    OnboardingKeyInput,
    OnboardingSetupCollapse,
    GlLink,
  },
  inject: {
    jitsuHost: {
      type: String,
    },
    jitsuProjectId: {
      type: String,
    },
  },
  computed: {
    instructions() {
      return {
        install: INSTALL_NPM_PACKAGE,
        esmSetup: this.replaceKeys(ESM_SETUP_WITH_NPM),
        commonJsSetup: this.replaceKeys(COMMON_JS_SETUP_WITH_NPM),
        htmlSetup: this.replaceKeys(HTML_SCRIPT_SETUP),
      };
    },
  },
  methods: {
    replaceKeys(template) {
      const hostKey = '$host';
      const appIdKey = '$applicationId';

      return template.replace(hostKey, this.jitsuHost).replace(appIdKey, this.jitsuProjectId);
    },
  },
  i18n: {
    title: s__('Product Analytics|Instrument your application'),
    description: s__(
      'Product Analytics|For the product analytics dashboard to start showing you some data, you need to add the analytics tracking code to your project.',
    ),
    introduction: s__(
      'Product Analytics|To instrument your application, select one of the options below. After an option has been instrumented and data is being collected, this page will progress to the next step.',
    ),
    learnMore: __('Learn more.'),
    sdkHost: s__('Product Analytics|SDK Host'),
    sdkHostDescription: s__('Product Analytics|The host to send all tracking events to'),
    sdkAppId: s__('Product Analytics|SDK App ID'),
    sdkAppIdDescription: s__('Product Analytics|Identifies the sender of tracking events'),
    esmModule: __('ESM module'),
    esmModuleDescription: s__('Product Analytics|Steps to add product analytics as an ESM module'),
    commonJsModule: __('CommonJS module'),
    commonJsModuleDescription: s__(
      'Product Analytics|Steps to add product analytics as a CommonJS module',
    ),
    htmlScriptTag: __('HTML script tag'),
    htmlScriptTagDescription: s__(
      'Product Analytics|Steps to add product analytics as a HTML script tag',
    ),
    addNpmPackage: s__(
      'Product Analytics|Add the NPM package to your package.json using your preferred package manager:',
    ),
    importNpmPackage: s__('Product Analytics|Import the new package into your JS code:'),
    addHtmlScriptToPage: s__(
      'Product Analytics|Add the script to the page and assign the client SDK to window:',
    ),
  },
  docsPath: helpPagePath('user/product_analytics/index'),
};
</script>

<template>
  <section>
    <h2 data-testid="title">{{ $options.i18n.title }}</h2>
    <p data-testid="description">
      {{ $options.i18n.description }}
      <gl-link data-testid="help-link" :href="$options.docsPath">
        {{ $options.i18n.learnMore }}
      </gl-link>
    </p>
    <p data-testid="introduction">{{ $options.i18n.introduction }}</p>

    <section class="gl-display-flex gl-flex-wrap gl-mb-6">
      <onboarding-key-input
        class="gl-mr-6"
        :label="$options.i18n.sdkHost"
        :description="$options.i18n.sdkHostDescription"
        :value="jitsuHost"
      />

      <onboarding-key-input
        :label="$options.i18n.sdkAppId"
        :description="$options.i18n.sdkAppIdDescription"
        :value="jitsuProjectId"
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
