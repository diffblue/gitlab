<script>
import { GlAccordion, GlAccordionItem, GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { DOC_PATH_SECURITY_SCANNER_INTEGRATION_REPORT } from 'ee/security_dashboard/constants';

export const TYPE_ERRORS = 'errors';
export const TYPE_WARNINGS = 'warnings';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAlert,
    GlButton,
    GlSprintf,
  },
  props: {
    scans: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
      validator: (value) => [TYPE_ERRORS, TYPE_WARNINGS].includes(value),
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
  },
  computed: {
    alertVariant() {
      return {
        [TYPE_ERRORS]: 'danger',
        [TYPE_WARNINGS]: 'warning',
      }[this.type];
    },
    scansWithTitles() {
      return this.scans.map((scan) => ({
        ...scan,
        issues: scan[this.type],
        accordionTitle: `${scan.name} (${scan[this.type].length})`,
      }));
    },
  },
  DOC_PATH_SECURITY_SCANNER_INTEGRATION_REPORT,
};
</script>

<template>
  <gl-alert :variant="alertVariant" :dismissible="false">
    <strong role="heading">
      {{ title }}
    </strong>
    <p class="gl-mt-3">
      <gl-sprintf :message="description" data-testid="description">
        <template #helpPageLink="{ content }">
          <gl-button
            variant="link"
            icon="external-link"
            :href="$options.DOC_PATH_SECURITY_SCANNER_INTEGRATION_REPORT"
            target="_blank"
          >
            {{ content }}
          </gl-button>
        </template>
      </gl-sprintf>
    </p>
    <gl-accordion :header-level="3">
      <gl-accordion-item
        v-for="{ name, issues, accordionTitle } in scansWithTitles"
        :key="name"
        :title="accordionTitle"
      >
        <ul class="gl-pl-4">
          <li v-for="issue in issues" :key="issue">{{ issue }}</li>
        </ul>
      </gl-accordion-item>
    </gl-accordion>
  </gl-alert>
</template>
