<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __, s__, sprintf } from '~/locale';
import { GEO_TROUBLESHOOTING_LINK } from '../constants';

export default {
  name: 'GeoReplicableEmptyState',
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  props: {
    geoReplicableEmptySvgPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['replicableTypeName', 'hasFilters']),
    title() {
      return this.hasFilters
        ? __('No results found')
        : sprintf(s__('Geo|There are no %{replicable} to show'), {
            replicable: this.replicableTypeName,
          });
    },
    description() {
      return this.hasFilters
        ? __('Edit your search filter and try again.')
        : s__(
            'Geo|No %{replicable} were found. If you believe this may be an error, please refer to the %{linkStart}Geo Troubleshooting%{linkEnd} documentation for more information.',
          );
    },
  },
  GEO_TROUBLESHOOTING_LINK,
};
</script>

<template>
  <gl-empty-state :title="title" :svg-path="geoReplicableEmptySvgPath">
    <template #description>
      <gl-sprintf :message="description">
        <template #replicable>
          <span>{{ replicableTypeName }}</span>
        </template>
        <template #link="{ content }">
          <gl-link :href="$options.GEO_TROUBLESHOOTING_LINK" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
