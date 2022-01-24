import { GlLoadingIcon, GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import { DropdownVariant } from 'ee/vue_shared/components/sidebar/epics_select//constants';
import EpicsSelectBase from 'ee/vue_shared/components/sidebar/epics_select/base.vue';
import DropdownValue from 'ee/vue_shared/components/sidebar/epics_select/dropdown_value.vue';
import DropdownValueCollapsed from 'ee/vue_shared/components/sidebar/epics_select/dropdown_value_collapsed.vue';

import createDefaultStore from 'ee/vue_shared/components/sidebar/epics_select/store';

import { mockEpic1, mockEpic2, mockAssignRemoveRes, mockIssue, noneEpic } from '../mock_data';

describe('EpicsSelect', () => {
  describe('Base', () => {
    let wrapper;
    let wrapperStandalone;
    const store = createDefaultStore();
    const storeStandalone = createDefaultStore();
    const props = {
      canEdit: true,
      initialEpic: mockEpic1,
      initialEpicLoading: false,
      epicIssueId: mockIssue.epic_issue_id,
      groupId: mockEpic1.group_id,
      issueId: mockIssue.id,
    };

    beforeEach(() => {
      wrapper = shallowMount(EpicsSelectBase, {
        store,
        propsData: {
          ...props,
        },
      });

      wrapperStandalone = shallowMount(EpicsSelectBase, {
        store: storeStandalone,
        propsData: {
          ...props,
          variant: DropdownVariant.Standalone,
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
      wrapperStandalone.destroy();
    });

    describe('computed', () => {
      describe('dropdownButtonTextClass', () => {
        it('should return object { is-default: true } when variant is "standalone"', () => {
          expect(wrapperStandalone.vm.dropdownButtonTextClass).toEqual(
            expect.objectContaining({
              'is-default': true,
            }),
          );
        });

        it('should return object { is-default: false } when variant is "sidebar"', () => {
          expect(wrapper.vm.dropdownButtonTextClass).toEqual(
            expect.objectContaining({
              'is-default': false,
            }),
          );
        });
      });
    });

    describe('watchers', () => {
      describe('issueId', () => {
        it('should update `issueId` within state when prop is updated', async () => {
          wrapper.setProps({
            issueId: 123,
          });

          await wrapper.vm.$nextTick();
          expect(wrapper.vm.$store.state.issueId).toBe(123);
        });
      });

      describe('initialEpic', () => {
        it('should update `selectedEpic` within state when prop is updated', async () => {
          wrapper.setProps({
            initialEpic: mockEpic2,
          });

          await wrapper.vm.$nextTick();
          expect(wrapper.vm.$store.state.selectedEpic).toBe(mockEpic2);
        });
      });

      describe('initialEpicLoading', () => {
        it('should update `selectedEpic` within state when prop is updated', async () => {
          wrapper.setProps({
            initialEpic: mockEpic2,
          });

          await wrapper.vm.$nextTick();
          expect(wrapper.vm.$store.state.selectedEpic).toBe(mockEpic2);
        });
      });

      describe('searchQuery', () => {
        beforeEach(() => {
          jest.spyOn(wrapper.vm, 'fetchEpics').mockImplementation(jest.fn());
        });

        it('should call action `fetchEpics` with `searchQuery` when value is set and `groupEpics` is empty', async () => {
          wrapper.vm.$store.dispatch('setSearchQuery', 'foo');

          await wrapper.vm.$nextTick();
          expect(wrapper.vm.fetchEpics).toHaveBeenCalledWith('foo');
        });

        it('should call action `fetchEpics` without any params when value is empty', async () => {
          wrapper.vm.$store.dispatch('setSearchQuery', '');

          await wrapper.vm.$nextTick();
          expect(wrapper.vm.fetchEpics).toHaveBeenCalledWith();
        });
      });
    });

    describe('methods', () => {
      describe('hideDropdown', () => {
        it('should set `isDropdownShowing` to false', () => {
          wrapper.vm.hideDropdown();

          expect(wrapper.vm.isDropdownShowing).toBe(false);
        });

        it('should set `isDropdownShowing` to true when dropdown variant is "standalone"', () => {
          wrapperStandalone.vm.hideDropdown();

          expect(wrapperStandalone.vm.isDropdownShowing).toBe(true);
        });

        it('should emit `hide` event', () => {
          wrapperStandalone.vm.hideDropdown();

          expect(wrapperStandalone.emitted().hide.length).toBe(1);
        });
      });

      describe('handleItemSelect', () => {
        it('should call `removeIssueFromEpic` with selected epic when `epic` param represents `No Epic` and `epicIssueId` is defined', () => {
          jest.spyOn(wrapper.vm, 'removeIssueFromEpic').mockReturnValue(
            Promise.resolve({
              data: mockAssignRemoveRes,
            }),
          );
          store.dispatch('setSelectedEpic', mockEpic1);

          wrapper.vm.handleItemSelect(noneEpic);

          expect(wrapper.vm.removeIssueFromEpic).toHaveBeenCalledWith(mockEpic1);
        });

        it('should call `assignIssueToEpic` with passed `epic` param when it does not represent `No Epic` and `issueId` prop is defined', () => {
          jest.spyOn(wrapper.vm, 'assignIssueToEpic').mockReturnValue(
            Promise.resolve({
              data: mockAssignRemoveRes,
            }),
          );

          wrapper.vm.handleItemSelect(mockEpic2);

          expect(wrapper.vm.assignIssueToEpic).toHaveBeenCalledWith(mockEpic2);
        });

        it('should emit component event `epicSelect` with both `epicIssueId` & `issueId` props are not defined', async () => {
          wrapperStandalone.setProps({
            issueId: 0,
            epicIssueId: 0,
          });

          await wrapperStandalone.vm.$nextTick();
          wrapperStandalone.vm.handleItemSelect(mockEpic2);

          expect(wrapperStandalone.emitted('epicSelect')).toBeTruthy();
          expect(wrapperStandalone.emitted('epicSelect')[0]).toEqual([mockEpic2]);
        });
      });
    });

    describe('template', () => {
      const showDropdown = (w = wrapper) => {
        w.setProps({
          canEdit: true,
        });
        w.setData({
          isDropdownShowing: true,
        });
      };

      it('should render component container element', () => {
        expect(wrapper.classes()).toEqual(['js-epic-block', 'block', 'epic']);

        expect(wrapperStandalone.classes()).toEqual(['js-epic-block']);
      });

      it('should render DropdownValueCollapsed component', () => {
        expect(wrapper.findComponent(DropdownValueCollapsed).exists()).toBe(true);
      });

      it('should not render DropdownValueCollapsed component when variant is "standalone"', () => {
        expect(wrapperStandalone.findComponent(DropdownValueCollapsed).exists()).toBe(false);
      });

      it('should render a dropdown title component', () => {
        expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
      });

      it('should not render a dropdown title component when variant is "standalone"', () => {
        expect(wrapperStandalone.findComponent(GlDropdown).find('.title').exists()).toBe(false);
      });

      it('should render DropdownValue component when `showDropdown` is false', async () => {
        wrapper.vm.showDropdown = false;

        await wrapper.vm.$nextTick();
        expect(wrapper.findComponent(DropdownValue).exists()).toBe(true);
      });

      it('should not render DropdownValue component when variant is "standalone"', () => {
        expect(wrapperStandalone.findComponent(DropdownValue).exists()).toBe(false);
      });

      it('should render dropdown container element when props `canEdit` & `showDropdown` are true', async () => {
        showDropdown();

        await wrapper.vm.$nextTick();
        expect(wrapper.find('.epic-dropdown-container').exists()).toBe(true);
        expect(wrapper.findComponent(GlDropdown).exists()).toBe(true);
      });

      it('should render dropdown container element when variant is "standalone"', () => {
        expect(wrapperStandalone.find('.epic-dropdown-container').exists()).toBe(true);
      });

      it('should render dropdown menu container element when props `canEdit` & `showDropdown` are true', async () => {
        showDropdown();

        await wrapper.vm.$nextTick();
        expect(wrapper.find('.dropdown-menu-epics').exists()).toBe(true);
      });

      it('should render a dropdown header component when props `canEdit` & `showDropdown` are true', async () => {
        showDropdown();

        await wrapper.vm.$nextTick();
        expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe('Assign Epic');
      });

      it('should render a dropdown header component when variant is "standalone"', async () => {
        showDropdown(wrapperStandalone);
        await wrapperStandalone.vm.$nextTick();
        expect(wrapper.findComponent(GlDropdown).props('headerText')).toBe('Assign Epic');
      });

      it('should render a list of dropdown items when props `canEdit` & `showDropdown` are true and `isEpicsLoading` is false and `receiveEpicsSuccess` returns a valid response of epics', async () => {
        showDropdown();
        store.dispatch('receiveEpicsSuccess', [mockEpic1]);

        await wrapper.vm.$nextTick();
        expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(2);
      });

      it('should render GlLoadingIcon component when props `canEdit` & `showDropdown` and `isEpicsLoading` are true', async () => {
        showDropdown();
        store.dispatch('requestEpics');

        await wrapper.vm.$nextTick();
        expect(wrapper.findComponent(GlDropdown).findComponent(GlLoadingIcon).exists()).toBe(true);
      });

      it('focuses on the input when the dropdown is shown', () => {
        wrapper = mount(EpicsSelectBase, { propsData: props });

        const spy = jest.spyOn(wrapper.findComponent(GlSearchBoxByType).vm, 'focusInput');

        wrapper.findComponent(GlDropdown).vm.$emit('shown');

        expect(spy).toHaveBeenCalledTimes(1);
      });
    });
  });
});
