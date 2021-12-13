<script>
import { GlIcon } from '@gitlab/ui';
import { isValidSlaDueAt } from 'ee/vue_shared/components/incidents/utils';
import ServiceLevelAgreement from 'ee_component/vue_shared/components/incidents/service_level_agreement.vue';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import getSlaIncidentDataQuery from './graphql/queries/get_sla_due_at.query.graphql';

export default {
  components: { GlIcon, ServiceLevelAgreement },
  inject: ['fullPath', 'iid', 'slaFeatureAvailable'],
  apollo: {
    slaDueAt: {
      query: getSlaIncidentDataQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update({ project }) {
        return project?.issue?.slaDueAt || null;
      },
      result({ data }) {
        const issue = data?.project?.issue;
        const isValidSla = isValidSlaDueAt(issue?.slaDueAt);

        // Render component
        this.hasData = isValidSla;

        // Render parent component
        this.$emit('update', isValidSla);
      },
      error() {
        createFlash({
          message: s__('Incident|There was an issue loading incident data. Please try again.'),
        });
      },
    },
  },
  data() {
    return {
      hasData: false,
      slaDueAt: null,
    };
  },
};
</script>

<template>
  <div v-if="slaFeatureAvailable && hasData">
    <span class="gl-font-weight-bold">{{ s__('HighlightBar|Time to SLA:') }}</span>
    <span class="gl-white-space-nowrap">
      <gl-icon name="timer" />
      <service-level-agreement :sla-due-at="slaDueAt" :issue-iid="iid" :project-path="fullPath" />
    </span>
  </div>
</template>
