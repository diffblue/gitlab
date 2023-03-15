<script>
import { mapActions } from 'vuex';
import { REMOVE_SITE_MODAL_ID } from 'ee/geo_sites/constants';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import GeoSiteActionsDesktop from './geo_site_actions_desktop.vue';
import GeoSiteActionsMobile from './geo_site_actions_mobile.vue';

export default {
  name: 'GeoSiteActions',
  components: {
    GeoSiteActionsMobile,
    GeoSiteActionsDesktop,
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
  },
  methods: {
    ...mapActions(['prepSiteRemoval']),
    async warnSiteRemoval() {
      await this.prepSiteRemoval(this.site.id);
      this.$root.$emit(BV_SHOW_MODAL, REMOVE_SITE_MODAL_ID);
    },
  },
};
</script>

<template>
  <div>
    <geo-site-actions-mobile class="gl-lg-display-none" :site="site" @remove="warnSiteRemoval" />
    <geo-site-actions-desktop
      class="gl-display-none gl-lg-display-flex"
      :site="site"
      @remove="warnSiteRemoval"
    />
  </div>
</template>
