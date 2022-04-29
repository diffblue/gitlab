<script>
import { GlBadge, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { PRIMARY_SITE_SETTINGS, SECONDARY_SITE_SETTINGS } from '../constants';
import GeoNodeForm from './geo_node_form.vue';

export default {
  name: 'GeoNodeFormApp',
  i18n: {
    editGeoSite: s__('Geo|Edit Geo Site'),
    addGeoSite: s__('Geo|Add New Site'),
    primary: s__('Geo|Primary'),
    secondary: s__('Geo|Secondary'),
    subTitle: s__(
      'Geo|Configure various settings for your %{siteType} site. %{linkStart}Learn more%{linkEnd}',
    ),
  },
  components: {
    GeoNodeForm,
    GlBadge,
    GlSprintf,
    GlLink,
  },
  props: {
    selectiveSyncTypes: {
      type: Object,
      required: true,
    },
    syncShardsOptions: {
      type: Array,
      required: true,
    },
    node: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    isNodePrimary() {
      return this.node && this.node.primary;
    },
    pageTitle() {
      return this.node ? this.$options.i18n.editGeoSite : this.$options.i18n.addGeoSite;
    },
    pillDetails() {
      return {
        variant: this.isNodePrimary ? 'info' : 'muted',
        label: this.isNodePrimary ? this.$options.i18n.primary : this.$options.i18n.secondary,
      };
    },
    pageSubtitle() {
      return {
        link: this.isNodePrimary ? PRIMARY_SITE_SETTINGS : SECONDARY_SITE_SETTINGS,
        siteType: this.isNodePrimary
          ? this.$options.i18n.primary.toLowerCase()
          : this.$options.i18n.secondary.toLowerCase(),
      };
    },
  },
};
</script>

<template>
  <article class="geo-node-form-container">
    <div class="gl-my-5">
      <div class="gl-display-flex gl-align-items-center gl-pb-3">
        <h2 class="gl-font-size-h2 gl-my-0">{{ pageTitle }}</h2>
        <gl-badge
          class="rounded-pill gl-font-sm gl-px-3 gl-py-2 gl-ml-3"
          :variant="pillDetails.variant"
          >{{ pillDetails.label }}</gl-badge
        >
      </div>
      <div data-testid="node-form-subtitle">
        <gl-sprintf :message="$options.i18n.subTitle">
          <template #siteType>
            <span>{{ pageSubtitle.siteType }}</span>
          </template>
          <template #link="{ content }">
            <gl-link :href="pageSubtitle.link" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
    </div>
    <geo-node-form v-bind="$props" />
  </article>
</template>
