<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import download from '~/lib/utils/downloader';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['vulnerabilitiesExportEndpoint'],
  data() {
    return {
      isPreparingCsvExport: false,
    };
  },
  methods: {
    initiateCsvExport() {
      this.isPreparingCsvExport = true;

      axios
        .post(this.vulnerabilitiesExportEndpoint)
        .then(({ data }) => pollUntilComplete(data._links.self))
        .then(({ data }) => {
          if (data.status !== 'finished') {
            throw new Error();
          }
          download({
            fileName: `csv-export-${formatDate(new Date(), 'isoDateTime')}.csv`,
            url: data._links.download,
          });
        })
        .catch(() => {
          createAlert({
            message: s__('SecurityReports|There was an error while generating the report.'),
          });
        })
        .finally(() => {
          this.isPreparingCsvExport = false;
        });
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip.hover
    :title="__('Export as CSV')"
    :loading="isPreparingCsvExport"
    :icon="isPreparingCsvExport ? '' : 'export'"
    @click="initiateCsvExport"
  >
    {{ __('Export') }}
  </gl-button>
</template>
