<script>
import { GlLink, GlButton, GlSprintf } from '@gitlab/ui';
import { mapGetters, mapState } from 'vuex';
import { GEO_REPLICATION_SUPPORTED_TYPES_URL } from 'ee/geo_nodes/constants';
import { s__ } from '~/locale';
import GeoNodeReplicationDetailsResponsive from './geo_node_replication_details_responsive.vue';
import GeoNodeReplicationStatusMobile from './geo_node_replication_status_mobile.vue';

export default {
  name: 'GeoNodeReplicationDetails',
  i18n: {
    replicationDetails: s__('Geo|Replication Details'),
    naVerificationHelpText: s__(
      'Geo|%{boldStart}Not applicable%{boldEnd}: Geo does not verify this component yet. See the %{linkStart}data types we plan to support%{linkEnd}.',
    ),
  },
  components: {
    GlLink,
    GlButton,
    GlSprintf,
    GeoNodeReplicationDetailsResponsive,
    GeoNodeReplicationStatusMobile,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      collapsed: false,
    };
  },
  computed: {
    ...mapState(['replicableTypes']),
    ...mapGetters(['verificationInfo', 'syncInfo']),
    replicationItems() {
      const syncInfoData = this.syncInfo(this.node.id);
      const verificationInfoData = this.verificationInfo(this.node.id);

      return this.replicableTypes.map((replicable) => {
        const replicableSyncInfo = syncInfoData.find((r) => r.title === replicable.titlePlural);

        const replicableVerificationInfo = verificationInfoData.find(
          (r) => r.title === replicable.titlePlural,
        );

        return {
          dataTypeTitle: replicable.dataTypeTitle,
          component: replicable.titlePlural,
          syncValues: replicableSyncInfo ? replicableSyncInfo.values : null,
          verificationValues: replicableVerificationInfo ? replicableVerificationInfo.values : null,
          replicationView: this.getReplicationView(replicable),
        };
      });
    },
    chevronIcon() {
      return this.collapsed ? 'chevron-right' : 'chevron-down';
    },
    hasNAVerificationType() {
      return this.replicationItems.some((item) => !item.verificationValues);
    },
  },
  methods: {
    collapseSection() {
      this.collapsed = !this.collapsed;
    },
    getReplicationView(replicable) {
      if (replicable.noReplicationView) {
        return null;
      }

      const path = replicable.customReplicationUrl
        ? `${this.node.url}${replicable.customReplicationUrl}`
        : `${this.node.url}admin/geo/sites/${this.node.id}/replication/${replicable.namePlural}`;

      return new URL(path).toString();
    },
  },
  GEO_REPLICATION_SUPPORTED_TYPES_URL,
};
</script>

<template>
  <div>
    <div class="gl-py-5 gl-border-b gl-border-t">
      <gl-button
        class="gl-mr-1 gl-p-0!"
        category="tertiary"
        variant="confirm"
        :icon="chevronIcon"
        @click="collapseSection"
      >
        {{ $options.i18n.replicationDetails }}
      </gl-button>
    </div>
    <div v-if="!collapsed">
      <geo-node-replication-details-responsive
        class="gl-display-none gl-md-display-block"
        :node-id="node.id"
        :replication-items="replicationItems"
        data-testid="geo-replication-details-desktop"
      />
      <geo-node-replication-details-responsive
        class="gl-md-display-none!"
        :node-id="node.id"
        :replication-items="replicationItems"
        data-testid="geo-replication-details-mobile"
      >
        <template #title="{ translations }">
          <span class="gl-font-weight-bold">{{ translations.component }}</span>
          <span class="gl-font-weight-bold">{{ translations.status }}</span>
        </template>
        <template #default="{ item, translations }">
          <div class="gl-mr-5" data-testid="replicable-component">
            <gl-link v-if="item.replicationView" :href="item.replicationView">{{
              item.component
            }}</gl-link>
            <span v-else>{{ item.component }}</span>
          </div>
          <geo-node-replication-status-mobile :item="item" :translations="translations" />
        </template>
      </geo-node-replication-details-responsive>
      <div v-if="hasNAVerificationType" class="gl-mt-4">
        <gl-sprintf :message="$options.i18n.naVerificationHelpText">
          <template #bold="{ content }">
            <span class="gl-font-weight-bold">{{ content }} </span>
          </template>
          <template #link="{ content }">
            <gl-link
              data-testid="naVerificationHelpLink"
              :href="$options.GEO_REPLICATION_SUPPORTED_TYPES_URL"
              target="_blank"
              >{{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
    </div>
  </div>
</template>
