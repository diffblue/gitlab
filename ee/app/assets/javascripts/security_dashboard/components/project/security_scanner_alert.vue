<script>
import { GlAlert, GlIntersperse, GlLink, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import { DOC_PATH_APPLICATION_SECURITY } from 'ee/security_dashboard/constants';

export default {
  components: {
    GlAlert,
    GlIntersperse,
    GlLink,
    GlSprintf,
  },
  inject: ['newProjectPipelinePath'],
  props: {
    notEnabledScanners: {
      type: Array,
      required: true,
    },
    noPipelineRunScanners: {
      type: Array,
      required: true,
    },
  },
  computed: {
    alertMessages() {
      return [
        {
          key: 'notEnabled',
          link: DOC_PATH_APPLICATION_SECURITY,
          content: this.notEnabledAlertMessage,
          scanners: this.notEnabledScanners,
        },
        {
          key: 'noPipelineRun',
          link: this.newProjectPipelinePath,
          content: this.noPipelineRunAlertMessage,
          scanners: this.noPipelineRunScanners,
        },
      ].filter(({ scanners }) => scanners.length > 0);
    },
    notEnabledAlertMessage() {
      return n__(
        '%{securityScanner} is not enabled for this project. %{linkStart}More information%{linkEnd}',
        '%{securityScanner} are not enabled for this project. %{linkStart}More information%{linkEnd}',
        this.notEnabledScanners.length,
      );
    },
    noPipelineRunAlertMessage() {
      return n__(
        '%{securityScanner} result is not available because a pipeline has not been run since it was enabled. %{linkStart}Run a pipeline%{linkEnd}',
        '%{securityScanner} results are not available because a pipeline has not been run since it was enabled. %{linkStart}Run a pipeline%{linkEnd}',
        this.noPipelineRunScanners.length,
      );
    },
  },
};
</script>

<template>
  <section>
    <gl-alert v-if="alertMessages.length > 0" variant="warning" @dismiss="$emit('dismiss')">
      <ul class="gl-list-style-none gl-mb-0 gl-pl-0">
        <li
          v-for="alertMessage in alertMessages"
          :key="alertMessage.key"
          :data-testid="alertMessage.key"
        >
          <gl-sprintf :message="alertMessage.content">
            <template #securityScanner>
              <gl-intersperse>
                <span v-for="scanner in alertMessage.scanners" :key="scanner">{{ scanner }}</span>
              </gl-intersperse>
            </template>
            <template #link="{ content }">
              <gl-link :href="alertMessage.link" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </li>
      </ul>
    </gl-alert>
  </section>
</template>
