import { GlDropdown, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import DevopsAdoptionAddDropdown from 'ee/analytics/devops_reports/devops_adoption/components/devops_adoption_add_dropdown.vue';
import {
  I18N_GROUP_DROPDOWN_TEXT,
  I18N_GROUP_DROPDOWN_HEADER,
  I18N_ADMIN_DROPDOWN_TEXT,
  I18N_ADMIN_DROPDOWN_HEADER,
  I18N_NO_SUB_GROUPS,
} from 'ee/analytics/devops_reports/devops_adoption/constants';
import bulkEnableDevopsAdoptionNamespacesMutation from 'ee/analytics/devops_reports/devops_adoption/graphql/mutations/bulk_enable_devops_adoption_namespaces.mutation.graphql';
import disableDevopsAdoptionNamespaceMutation from 'ee/analytics/devops_reports/devops_adoption/graphql/mutations/disable_devops_adoption_namespace.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  groupNodes,
  groupGids,
  devopsAdoptionNamespaceData,
  genericDeleteErrorMessage,
} from '../mock_data';

Vue.use(VueApollo);

const mutateAdd = jest.fn().mockResolvedValue({
  data: {
    bulkEnableDevopsAdoptionNamespaces: {
      enabledNamespaces: [devopsAdoptionNamespaceData.nodes[0]],
      errors: [],
    },
  },
});
const mutateDisable = jest.fn().mockResolvedValue({
  data: {
    disableDevopsAdoptionNamespace: {
      errors: [],
    },
  },
});

const mutateWithErrors = jest.fn().mockRejectedValue(genericDeleteErrorMessage);

describe('DevopsAdoptionAddDropdown', () => {
  let wrapper;

  const createComponent = ({
    enableNamespaceSpy = mutateAdd,
    disableNamespaceSpy = mutateDisable,
    provide = {},
    props = {},
  } = {}) => {
    const mockApollo = createMockApollo([
      [bulkEnableDevopsAdoptionNamespacesMutation, enableNamespaceSpy],
      [disableDevopsAdoptionNamespaceMutation, disableNamespaceSpy],
    ]);

    wrapper = shallowMountExtended(DevopsAdoptionAddDropdown, {
      apolloProvider: mockApollo,
      propsData: {
        groups: [],
        ...props,
      },
      provide,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        GlDropdown,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const clickFirstRow = () => wrapper.findByTestId('group-row').trigger('click');

  describe('default behaviour', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays a dropdown component', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('displays the correct text', () => {
      const dropdown = findDropdown();

      expect(dropdown.props('text')).toBe(I18N_ADMIN_DROPDOWN_TEXT);
      expect(dropdown.props('headerText')).toBe(I18N_ADMIN_DROPDOWN_HEADER);
    });

    it('is disabled', () => {
      expect(findDropdown().props('disabled')).toBe(true);
    });

    it('displays a tooltip', () => {
      const tooltip = getBinding(findDropdown().element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe(I18N_NO_SUB_GROUPS);
    });
  });

  describe('with isGroup === true', () => {
    it('displays the correct text', () => {
      createComponent({ provide: { isGroup: true } });

      const dropdown = findDropdown();

      expect(dropdown.props('text')).toBe(I18N_GROUP_DROPDOWN_TEXT);
      expect(dropdown.props('headerText')).toBe(I18N_GROUP_DROPDOWN_HEADER);
    });
  });

  describe('with sub-groups available', () => {
    describe('displays the correct components', () => {
      beforeEach(() => {
        createComponent({ props: { hasSubgroups: true } });
      });

      it('is enabled', () => {
        expect(findDropdown().props('disabled')).toBe(false);
      });

      it('does not display a tooltip', () => {
        const tooltip = getBinding(findDropdown().element, 'gl-tooltip');

        expect(tooltip.value).toBe(false);
      });

      it('displays the no results message', () => {
        const noResultsRow = wrapper.findByTestId('no-results');

        expect(noResultsRow.exists()).toBe(true);
        expect(noResultsRow.text()).toBe('No results…');
      });
    });

    describe('with group data', () => {
      it('displays the corrent number of rows', () => {
        createComponent({ props: { hasSubgroups: true, groups: groupNodes } });

        expect(wrapper.findAllByTestId('group-row')).toHaveLength(groupNodes.length);
      });

      describe('on row click', () => {
        describe.each`
          level      | groupGid        | enabledNamespaces
          ${'group'} | ${groupGids[0]} | ${undefined}
          ${'group'} | ${groupGids[0]} | ${devopsAdoptionNamespaceData}
          ${'admin'} | ${null}         | ${undefined}
          ${'admin'} | ${null}         | ${devopsAdoptionNamespaceData}
        `('$level level sucessful request', ({ groupGid, enabledNamespaces }) => {
          beforeEach(() => {
            createComponent({
              props: { hasSubgroups: true, groups: groupNodes, enabledNamespaces },
              provide: { groupGid },
            });

            clickFirstRow();
          });

          if (!enabledNamespaces) {
            it('makes a request to enable the selected group', () => {
              expect(mutateAdd).toHaveBeenCalledWith({
                displayNamespaceId: groupGid,
                namespaceIds: [groupGids[0]],
              });
            });

            it('emits the enabledNamespacesAdded event', () => {
              const [params] = wrapper.emitted().enabledNamespacesAdded[0];

              expect(params).toEqual([devopsAdoptionNamespaceData.nodes[0]]);
            });
          } else {
            it('makes a request to disable the selected group', () => {
              expect(mutateDisable).toHaveBeenCalledWith({
                id: devopsAdoptionNamespaceData.nodes[0].id,
              });
            });

            it('emits the enabledNamespacesRemoved event', () => {
              const [params] = wrapper.emitted().enabledNamespacesRemoved[0];

              expect(params).toBe(devopsAdoptionNamespaceData.nodes[0].id);
            });
          }
        });

        describe('on error', () => {
          beforeEach(async () => {
            jest.spyOn(Sentry, 'captureException');

            createComponent({
              enableNamespaceSpy: mutateWithErrors,
              props: { hasSubgroups: true, groups: groupNodes },
            });

            clickFirstRow();
            await waitForPromises();
          });

          it('calls sentry', async () => {
            await waitForPromises();
            expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(
              genericDeleteErrorMessage,
            );
          });

          it('does not emit the enabledNamespacesAdded event', () => {
            expect(wrapper.emitted().enabledNamespacesAdded).not.toBeDefined();
          });
        });
      });
    });

    describe('while loading', () => {
      beforeEach(() => {
        createComponent({ props: { isLoadingGroups: true } });
      });

      it('displays a loading icon', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });

      it('does not display any rows', () => {
        expect(wrapper.findAllByTestId('group-row')).toHaveLength(0);
      });
    });

    describe('searching', () => {
      it('emits the fetchGroups event', () => {
        createComponent({ props: { hasSubgroups: true } });

        wrapper.findComponent(GlSearchBoxByType).vm.$emit('input', 'blah');

        jest.runAllTimers();

        const [params] = wrapper.emitted().fetchGroups[0];

        expect(params).toBe('blah');
      });
    });
  });
});
