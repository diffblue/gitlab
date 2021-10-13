import Vue from 'vue';
import VueRouter from 'vue-router';
import { joinPaths } from '~/lib/utils/url_utility';

Vue.use(VueRouter);

export const createRouter = (base) =>
  new VueRouter({
    mode: 'hash',
    base: joinPaths(gon.relative_url_root || '', base),
    routes: [
      {
        path: '/:tabId',
        name: 'tab',
      },
    ],
  });
