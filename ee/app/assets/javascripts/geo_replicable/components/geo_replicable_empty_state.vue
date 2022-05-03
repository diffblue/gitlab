<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { mapGetters } from 'vuex';

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
    geoTroubleshootingLink: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['replicableTypeName']),
  },
};
</script>

<template>
  <gl-empty-state
    :title="
      /* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */
      sprintf(__('There are no %{replicableTypeName} to show'), {
        replicableTypeName,
      }) /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */
    "
    :svg-path="geoReplicableEmptySvgPath"
  >
    <template #description>
      <p>
        <gl-sprintf
          :message="
            s__(
              'Geo|Adjust your filters/search criteria above. If you believe this may be an error, please refer to the %{linkStart}Geo Troubleshooting%{linkEnd} documentation for more information.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="geoTroubleshootingLink" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-empty-state>
</template>
