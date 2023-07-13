import Vue from 'vue';
import VueRouter from 'vue-router';
import WorkspacesList from '../pages/list.vue';
import CreateWorkspace from '../pages/create.vue';
import { ROUTES } from '../constants';

Vue.use(VueRouter);

export default function createRouter({ base }) {
  const routes = [
    {
      path: '/',
      name: ROUTES.index,
      component: WorkspacesList,
    },
    {
      path: '/new',
      name: ROUTES.new,
      component: CreateWorkspace,
    },
    {
      path: '*',
      redirect: '/',
    },
  ];

  return new VueRouter({
    base,
    mode: 'history',
    routes,
  });
}
