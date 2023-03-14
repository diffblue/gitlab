import { GlIcon, GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import GeoSiteFormShards from 'ee/geo_site_form/components/geo_site_form_shards.vue';
import { MOCK_SYNC_SHARDS } from '../mock_data';

describe('GeoSiteFormShards', () => {
  let wrapper;

  const defaultProps = {
    selectedShards: [],
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = (props = {}) => {
    wrapper = mount(GeoSiteFormShards, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

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
          expect(wrapper.emitted()).toHaveProperty('removeSyncOption');
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
          expect(wrapper.emitted()).toHaveProperty('addSyncOption');
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
          expect(wrapper.vm.isSelected(MOCK_SYNC_SHARDS[0])).toBe(true);
        });
      });

      describe('when shard is not in selectedShards', () => {
        beforeEach(() => {
          createComponent({
            selectedShards: [MOCK_SYNC_SHARDS[0].value],
          });
        });

        it('returns `false`', () => {
          expect(wrapper.vm.isSelected(MOCK_SYNC_SHARDS[1])).toBe(false);
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
            expect(wrapper.vm.dropdownTitle).toBe(GeoSiteFormShards.i18n.noSelectedDropdownTitle);
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
            expect(wrapper.vm.noSyncShards).toBe(false);
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
          expect(wrapper.vm.noSyncShards).toBe(true);
        });
      });
    });
  });
});
