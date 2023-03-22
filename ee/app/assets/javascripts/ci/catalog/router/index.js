import Vue from 'vue';
import VueRouter from 'vue-router';
import { routes } from './routes';

Vue.use(VueRouter);

export const createRouter = (base) => {
  return new VueRouter({
    base,
    mode: 'history',
    routes,
  });
};
