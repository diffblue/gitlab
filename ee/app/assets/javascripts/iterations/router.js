import Vue from 'vue';
import VueRouter from 'vue-router';
import { __, s__ } from '~/locale';
import IterationCadenceForm from './components/iteration_cadence_form.vue';
import IterationCadenceList from './components/iteration_cadences_list.vue';
import IterationForm from './components/iteration_form.vue';
import IterationReport from './components/iteration_report.vue';

Vue.use(VueRouter);

function checkPermission(permission) {
  return (to, from, next) => {
    if (permission) {
      next();
    } else {
      next({ name: 'index' });
    }
  };
}

function renderChildren(children) {
  return {
    component: {
      render(createElement) {
        return createElement('router-view');
      },
    },
    children: [
      ...children,
      {
        path: '*',
        redirect: '/',
      },
    ],
  };
}

export default function createRouter({ base, permissions = {} }) {
  const routes = [
    {
      path: '/',
      meta: {
        breadcrumb: s__('Iterations|Iteration cadences'),
      },
      ...renderChildren([
        {
          name: 'index',
          path: '',
          component: IterationCadenceList,
        },
        {
          name: 'new',
          path: 'new',
          component: IterationCadenceForm,
          beforeEnter: checkPermission(permissions.canCreateCadence),
          meta: {
            breadcrumb: s__('Iterations|New iteration cadence'),
          },
        },
        {
          path: '/:cadenceId',
          ...renderChildren([
            {
              name: 'cadence',
              path: '/:cadenceId',
              redirect: '/',
            },
            {
              name: 'edit',
              path: '/:cadenceId/edit',
              component: IterationCadenceForm,
              beforeEnter: checkPermission(permissions.canEditCadence),
              meta: {
                breadcrumb: __('Edit'),
              },
            },
            {
              path: 'iterations',
              meta: {
                breadcrumb: __('Iterations'),
              },
              ...renderChildren([
                {
                  name: 'iterations',
                  path: '/:cadenceId/iterations',
                  redirect: '/',
                },
                {
                  name: 'newIteration',
                  path: '/:cadenceId/iterations/new',
                  component: IterationForm,
                  beforeEnter: checkPermission(permissions.canCreateIteration),
                  meta: {
                    breadcrumb: s__('Iterations|New iteration'),
                  },
                },
                {
                  path: ':iterationId',
                  ...renderChildren([
                    {
                      name: 'iteration',
                      path: '/:cadenceId/iterations/:iterationId',
                      component: IterationReport,
                    },
                    {
                      name: 'editIteration',
                      path: '/:cadenceId/iterations/:iterationId/edit',
                      component: IterationForm,
                      beforeEnter: checkPermission(permissions.canEditIteration),
                      meta: {
                        breadcrumb: __('Edit'),
                      },
                    },
                  ]),
                },
              ]),
            },
          ]),
        },
      ]),
    },
  ];

  const router = new VueRouter({
    base,
    mode: 'history',
    routes,
  });

  return router;
}
