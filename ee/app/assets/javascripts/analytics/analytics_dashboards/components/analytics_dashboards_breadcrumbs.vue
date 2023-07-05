<script>
import { GlBreadcrumb } from '@gitlab/ui';

export default {
  components: {
    GlBreadcrumb,
  },
  computed: {
    rootRoute() {
      return this.$router.options.routes.find((r) => r.meta.root);
    },
    isRootRoute() {
      return this.$route.name === this.rootRoute.name;
    },
    rootRouteName() {
      return this.rootRoute.meta.getName();
    },
    routeName() {
      return this.$route.meta.getName();
    },
    rootRoutePath() {
      return this.rootRoute.path;
    },
    allCrumbs() {
      const crumbs = [
        {
          text: this.rootRouteName,
          to: this.rootRoutePath,
        },
      ];

      if (!this.isRootRoute && this.routeName) {
        crumbs.push({
          text: this.routeName,
          // Setting this to undefined allows us to keep the query params in
          // the event the user clicks on the breadcrumb for the current route
          to: undefined,
        });
      }

      return crumbs;
    },
  },
};
</script>

<template>
  <gl-breadcrumb :items="allCrumbs" />
</template>
