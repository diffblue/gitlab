<script>
import { GlPopover, GlIcon, GlLink, GlButton, GlTooltipDirective } from '@gitlab/ui';
import createFlash from '~/flash';
import AccessorUtils from '~/lib/utils/accessor';
import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import download from '~/lib/utils/downloader';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import { __, s__ } from '~/locale';

export const STORAGE_KEY = 'vulnerability_csv_export_popover_dismissed';

export default {
  components: {
    GlIcon,
    GlButton,
    GlPopover,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['vulnerabilitiesExportEndpoint'],
  data() {
    return {
      isPreparingCsvExport: false,
      showPopover: localStorage.getItem(STORAGE_KEY) !== 'true',
    };
  },
  computed: {
    buttonProps() {
      const { isPreparingCsvExport } = this;
      return {
        title: __('Export as CSV'),
        loading: isPreparingCsvExport,
        ...(!isPreparingCsvExport ? { icon: 'export' } : {}),
      };
    },
  },
  methods: {
    closePopover() {
      this.showPopover = false;

      if (AccessorUtils.canUseLocalStorage()) {
        localStorage.setItem(STORAGE_KEY, 'true');
      }
    },
    initiateCsvExport() {
      this.isPreparingCsvExport = true;
      this.closePopover();

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
          createFlash({
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
    ref="csvExportButton"
    v-gl-tooltip.hover
    class="gl-align-self-center"
    v-bind="buttonProps"
    @click="initiateCsvExport"
  >
    {{ __('Export') }}
    <gl-popover
      v-if="showPopover"
      ref="popover"
      :target="() => $refs.csvExportButton.$el"
      show
      placement="left"
      triggers="manual"
    >
      <p class="gl-font-base">
        {{ __('You can now export your security dashboard to a CSV report.') }}
      </p>
      <gl-link
        ref="popoverExternalLink"
        target="_blank"
        href="https://gitlab.com/gitlab-org/gitlab/issues/197111"
        class="d-flex align-items-center mb-3"
      >
        {{ __('More information and share feedback') }}
        <gl-icon name="external-link" :size="12" class="ml-1" />
      </gl-link>
      <gl-button
        ref="popoverButton"
        class="w-100"
        data-qa-selector="export_csv_modal_button"
        @click="closePopover"
      >
        {{ __('Got it!') }}
      </gl-button>
    </gl-popover>
  </gl-button>
</template>
