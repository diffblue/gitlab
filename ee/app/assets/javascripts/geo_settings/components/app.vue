<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import GeoSettingsForm from './geo_settings_form.vue';

export default {
  name: 'GeoSettingsApp',
  i18n: {
    geoSettingsTitle: s__('Geo|Geo Settings'),
    geoSettingsSubtitle: s__(
      'Geo|Set the timeout in seconds to send a secondary site status to the primary and IPs allowed for the secondary sites.',
    ),
  },
  components: {
    GlLoadingIcon,
    GeoSettingsForm,
  },
  computed: {
    ...mapState(['isLoading']),
  },
  created() {
    this.fetchGeoSettings();
  },
  methods: {
    ...mapActions(['fetchGeoSettings']),
  },
};
</script>

<template>
  <article data-testid="geoSettingsContainer">
    <h1 class="page-title gl-font-size-h-display">{{ $options.i18n.geoSettingsTitle }}</h1>
    <p>{{ $options.i18n.geoSettingsSubtitle }}</p>
    <gl-loading-icon v-if="isLoading" size="xl" />
    <geo-settings-form v-else />
  </article>
</template>
