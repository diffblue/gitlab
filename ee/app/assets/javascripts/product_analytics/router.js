import Vue from 'vue';
import VueRouter from 'vue-router';

Vue.use(VueRouter);

export default () => {
  return new VueRouter({
    mode: 'history',
    base: `${window.location.pathname
      .split('/-/product_analytics/dashboards')[0]
      .replace(/\/$/, '')}/-/product_analytics/dashboards`,
    routes: [],
  });
};
