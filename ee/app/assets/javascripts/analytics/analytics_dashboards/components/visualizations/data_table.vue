<script>
import { GlIcon, GlLink, GlTableLite } from '@gitlab/ui';
import { __ } from '~/locale';
import { isExternal } from '~/lib/utils/url_utility';

export default {
  name: 'DataTable',
  components: {
    GlIcon,
    GlLink,
    GlTableLite,
  },
  props: {
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    // Part of the visualizations API, but left unused for tables.
    // It could be used down the line to allow users to customize tables.
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    fields() {
      if (this.data.length < 1) {
        return null;
      }

      return Object.keys(this.data[0]).map((key) => ({
        key,
        tdClass: 'gl-text-truncate gl-max-w-0',
      }));
    },
  },
  methods: {
    isLink(value) {
      return Boolean(value?.text && value?.href);
    },
    isExternalLink(href) {
      return isExternal(href);
    },
  },
  i18n: {
    externalLink: __('external link'),
  },
};
</script>

<template>
  <div>
    <gl-table-lite :fields="fields" :items="data" hover responsive class="gl-mt-4">
      <template #cell()="{ value }">
        <gl-link v-if="isLink(value)" :href="value.href" is-unsafe-link
          >{{ value.text }}
          <gl-icon
            v-if="isExternalLink(value.href)"
            name="external-link"
            :size="12"
            :aria-label="$options.i18n.externalLink"
            class="gl-ml-1"
          />
        </gl-link>
        <template v-else>
          {{ value }}
        </template>
      </template>
    </gl-table-lite>
  </div>
</template>
