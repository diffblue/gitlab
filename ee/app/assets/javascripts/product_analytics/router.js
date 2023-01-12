import Vue from 'vue';
import VueRouter from 'vue-router';

Vue.use(VueRouter);

export default (base) => {
  return new VueRouter({
    mode: 'history',
    base,
    routes: [],
  });
};
