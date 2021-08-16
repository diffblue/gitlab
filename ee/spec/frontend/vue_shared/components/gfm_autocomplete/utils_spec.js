import {
  GfmAutocompleteType,
  tributeConfig,
} from 'ee/vue_shared/components/gfm_autocomplete/utils';

describe('ee gfm_autocomplete/utils', () => {
  describe('epics config', () => {
    const epicsConfig = tributeConfig[GfmAutocompleteType.Epics].config;
    const epic = {
      id: null,
      iid: 123456,
      title: "Epic title <script>alert('hi')</script>",
    };

    const subgroupEpic = {
      iid: 987654,
      reference: 'gitlab&987654',
      title: "Subgroup context epic title <script>alert('hi')</script>",
    };

    it('uses & as the trigger', () => {
      expect(epicsConfig.trigger).toBe('&');
    });

    it('inserts the iid on autocomplete selection', () => {
      expect(epicsConfig.fillAttr).toBe('iid');
    });

    it('searches using both the iid and title', () => {
      expect(epicsConfig.lookup(epic)).toBe(`${epic.iid}${epic.title}`);
    });

    it('limits the number of rendered items to 100', () => {
      expect(epicsConfig.menuItemLimit).toBe(100);
    });

    it('shows the iid and title in the menu item', () => {
      expect(epicsConfig.menuItemTemplate({ original: epic })).toMatchSnapshot();
    });

    it('inserts the iid on autocomplete selection within a top level group context', () => {
      expect(epicsConfig.selectTemplate({ original: epic })).toBe(`&${epic.iid}`);
    });

    it('inserts the reference on autocomplete selection within a group context', () => {
      expect(epicsConfig.selectTemplate({ original: subgroupEpic })).toBe(subgroupEpic.reference);
    });
  });
});
