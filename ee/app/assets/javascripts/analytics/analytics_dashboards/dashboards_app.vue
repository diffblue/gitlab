<script>
import Vue from 'vue';
import { GlToast } from '@gitlab/ui';

Vue.use(GlToast);

export default {
  name: 'DashboardsApp',
};
</script>

<template>
  <router-view ref="router-view" />
</template>
