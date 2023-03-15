<script>
import GeoSiteDetails from './details/geo_site_details.vue';
import GeoSiteHeader from './header/geo_site_header.vue';

export default {
  name: 'GeoSites',
  components: {
    GeoSiteHeader,
    GeoSiteDetails,
  },
  props: {
    site: {
      type: Object,
      required: true,
      validator: (value) => ['id', 'name', 'url'].every((prop) => value[prop]),
    },
  },
  data() {
    return {
      collapsed: false,
    };
  },
  methods: {
    toggleCollapse() {
      this.collapsed = !this.collapsed;
    },
  },
};
</script>

<template>
  <div class="gl-mb-4">
    <geo-site-header :site="site" :collapsed="collapsed" @collapse="toggleCollapse" />
    <geo-site-details v-if="!collapsed" :site="site" />
  </div>
</template>
