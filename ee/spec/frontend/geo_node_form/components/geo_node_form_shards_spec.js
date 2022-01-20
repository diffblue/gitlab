import { GlIcon, GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import GeoNodeFormShards from 'ee/geo_node_form/components/geo_node_form_shards.vue';
import { MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoNodeFormShards', () => {
  let wrapper;

  const defaultProps = {
    selectedShards: [],
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = (props = {}) => {
    wrapper = mount(GeoNodeFormShards, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => findGlDropdown().findAll('li');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlDropdown', () => {
      expect(findGlDropdown().exists()).toBe(true);
    });

    describe('DropdownItems', () => {
      beforeEach(() => {
        createComponent({
          selectedShards: [MOCK_SYNC_SHARDS[0].value],
        });
      });

      it('renders an instance for each shard', () => {
        const dropdownItems = findDropdownItems();

        dropdownItems.wrappers.forEach((dI, index) => {
          expect(dI.html()).toContain(wrapper.vm.syncShardsOptions[index].label);
        });
      });

      it('hides GlIcon if shard not in selectedShards', () => {
        const dropdownItems = findDropdownItems();

        dropdownItems.wrappers.forEach((dI, index) => {
          const dropdownItemIcon = dI.findComponent(GlIcon);

          expect(dropdownItemIcon.classes('invisible')).toBe(
            !wrapper.vm.isSelected(wrapper.vm.syncShardsOptions[index]),
          );
        });
      });
    });
  });

  describe('methods', () => {
    describe('toggleShard', () => {
      describe('when shard is in selectedShards', () => {
        beforeEach(() => {
          createComponent({
            selectedShards: [MOCK_SYNC_SHARDS[0].value],
          });
        });

        it('emits `removeSyncOption`', () => {
          wrapper.vm.toggleShard(MOCK_SYNC_SHARDS[0]);
          expect(wrapper.emitted('removeSyncOption')).toBeTruthy();
        });
      });

      describe('when shard is not in selectedShards', () => {
        beforeEach(() => {
          createComponent({
            selectedShards: [MOCK_SYNC_SHARDS[0].value],
          });
        });

        it('emits `addSyncOption`', () => {
          wrapper.vm.toggleShard(MOCK_SYNC_SHARDS[1]);
          expect(wrapper.emitted('addSyncOption')).toBeTruthy();
        });
      });
    });

    describe('isSelected', () => {
      describe('when shard is in selectedShards', () => {
        beforeEach(() => {
          createComponent({
            selectedShards: [MOCK_SYNC_SHARDS[0].value],
          });
        });

        it('returns `true`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_SHARDS[0])).toBeTruthy();
        });
      });

      describe('when shard is not in selectedShards', () => {
        beforeEach(() => {
          createComponent({
            selectedShards: [MOCK_SYNC_SHARDS[0].value],
          });
        });

        it('returns `false`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_SHARDS[1])).toBeFalsy();
        });
      });
    });

    describe('computed', () => {
      describe('dropdownTitle', () => {
        describe('when selectedShards is empty', () => {
          beforeEach(() => {
            createComponent({
              selectedShards: [],
            });
          });

          it('returns `Select shards to replicate`', () => {
            expect(wrapper.vm.dropdownTitle).toBe('Select shards to replicate');
          });
        });

        describe('when selectedShards length === 1', () => {
          beforeEach(() => {
            createComponent({
              selectedShards: [MOCK_SYNC_SHARDS[0].value],
            });
          });

          it('returns `this.selectedShards.length` shard selected', () => {
            expect(wrapper.vm.dropdownTitle).toBe(
              `${wrapper.vm.selectedShards.length} shard selected`,
            );
          });
        });

        describe('when selectedShards length > 1', () => {
          beforeEach(() => {
            createComponent({
              selectedShards: [MOCK_SYNC_SHARDS[0].value, MOCK_SYNC_SHARDS[1].value],
            });
          });

          it('returns `this.selectedShards.length` shards selected', () => {
            expect(wrapper.vm.dropdownTitle).toBe(
              `${wrapper.vm.selectedShards.length} shards selected`,
            );
          });
        });
      });

      describe('noSyncShards', () => {
        describe('when syncShardsOptions.length > 0', () => {
          beforeEach(() => {
            createComponent();
          });

          it('returns `false`', () => {
            expect(wrapper.vm.noSyncShards).toBeFalsy();
          });
        });
      });

      describe('when syncShardsOptions.length === 0', () => {
        beforeEach(() => {
          createComponent({
            syncShardsOptions: [],
          });
        });

        it('returns `true`', () => {
          expect(wrapper.vm.noSyncShards).toBeTruthy();
        });
      });
    });
  });
});
