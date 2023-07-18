<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';

import {
  INSTALL_NPM_PACKAGE,
  IMPORT_NPM_PACKAGE,
  INIT_TRACKING,
  HTML_SCRIPT_SETUP,
  BROWSER_SDK_DOCS_URL,
} from 'ee/product_analytics/onboarding/constants';

export default {
  name: 'ProductAnalyticsInstrumentationInstructions',
  components: {
    GlLink,
    GlSprintf,
  },
  inject: {
    collectorHost: {
      type: String,
    },
  },
  props: {
    trackingKey: {
      type: String,
      required: true,
    },
    dashboardsPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    instructions() {
      return {
        install: INSTALL_NPM_PACKAGE,
        import: IMPORT_NPM_PACKAGE,
        init: INIT_TRACKING,
        htmlSetup: HTML_SCRIPT_SETUP,
      };
    },
  },
  i18n: {
    sdkClientsTitle: s__('ProductAnalytics|SDK clients'),
    sdkHost: s__('ProductAnalytics|SDK host'),
    sdkHostDescription: s__('ProductAnalytics|The host to send all tracking events to'),
    sdkAppId: s__('ProductAnalytics|SDK application ID'),
    sdkAppIdDescription: s__('ProductAnalytics|The sender of tracking events'),
    instrumentAppDescription: s__(
      'ProductAnalytics|You can instrument your application using a JS module or an HTML script. Follow the instructions below for the option you prefer.',
    ),
    jsModuleTitle: s__('ProductAnalytics|Using JS module'),
    addNpmPackage: s__(
      'ProductAnalytics|1. Add the NPM package to your package.json using your preferred package manager',
    ),
    importNpmPackage: s__('ProductAnalytics|2. Import the new package into your JS code'),
    initNpmPackage: s__('ProductAnalytics|3. Initiate the tracking'),
    htmlScriptTag: __('Using HTML script'),
    htmlScriptTagDescription: s__(
      'ProductAnalytics|Add the script to the page and assign the client SDK to window',
    ),
    summaryText: s__(
      'ProductAnalytics|After your application has been instrumented and data is being collected, you can visualize and monitor behaviors in your %{linkStart}analytics dashboards%{linkEnd}.',
    ),
    furtherBrowserSDKInfo: s__(
      `ProductAnalytics|For more information, see the %{linkStart}docs%{linkEnd}.`,
    ),
  },
  BROWSER_SDK_DOCS_URL,
};
</script>

<template>
  <div>
    <section>
      <p>{{ $options.i18n.instrumentAppDescription }}</p>

      <section class="gl-mb-6" data-testid="npm-instrumentation-instructions">
        <h5 class="gl-mb-5">{{ $options.i18n.jsModuleTitle }}</h5>

        <strong class="gl-display-block gl-mb-3">{{ $options.i18n.addNpmPackage }}</strong>
        <pre class="gl-mb-5">{{ instructions.install }}</pre>
        <strong class="gl-display-block gl-mt-5 gl-mb-3">{{
          $options.i18n.importNpmPackage
        }}</strong>
        <pre class="gl-mb-5">{{ instructions.import }}</pre>
        <strong class="gl-display-block gl-mt-5 gl-mb-3">{{ $options.i18n.initNpmPackage }}</strong>
        <pre class="gl-mb-5"><gl-sprintf :message="instructions.init">
          <template #appId><span>{{ trackingKey }}</span></template>
          <template #host><span>{{ collectorHost }}</span></template>
        </gl-sprintf></pre>
      </section>

      <section class="gl-mb-6" data-testid="html-instrumentation-instructions">
        <h5 class="gl-mb-5 gl-w-full">{{ $options.i18n.htmlScriptTag }}</h5>
        <strong class="gl-display-block gl-mb-3">{{
          $options.i18n.htmlScriptTagDescription
        }}</strong>
        <pre class="gl-mb-5"><gl-sprintf :message="instructions.htmlSetup">
          <template #appId><span>{{ trackingKey }}</span></template>
          <template #host><span>{{ collectorHost }}</span></template>
        </gl-sprintf></pre>
      </section>
    </section>

    <p>
      <gl-sprintf
        :message="$options.i18n.furtherBrowserSDKInfo"
        data-testid="further-browser-sdk-info"
      >
        <template #link="{ content }">
          <gl-link :href="$options.BROWSER_SDK_DOCS_URL">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p>
      <gl-sprintf :message="$options.i18n.summaryText" data-testid="summary-text">
        <template #link="{ content }">
          <gl-link :href="dashboardsPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
