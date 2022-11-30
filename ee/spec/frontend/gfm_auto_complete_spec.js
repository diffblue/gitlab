import $ from 'jquery';
import GfmAutoCompleteEE from 'ee/gfm_auto_complete';
import { TEST_HOST } from 'helpers/test_constants';
import GfmAutoComplete from '~/gfm_auto_complete';

describe('GfmAutoCompleteEE', () => {
  const dataSources = {
    labels: `${TEST_HOST}/autocomplete_sources/labels`,
  };
  let instance;
  const $input = $('<input type="text" />');

  beforeEach(() => {
    instance = new GfmAutoCompleteEE(dataSources);
    instance.setup($input);
  });

  it('should have enableMap', () => {
    expect(instance.enableMap).not.toBeNull();
  });

  describe('Issues.templateFunction', () => {
    it('should return html with id and title', () => {
      expect(GfmAutoComplete.Issues.templateFunction({ id: 42, title: 'Sample Epic' })).toBe(
        '<li><small>42</small> Sample Epic</li>',
      );
    });

    it('should replace id with reference if reference is set', () => {
      expect(
        GfmAutoComplete.Issues.templateFunction({
          id: 42,
          title: 'Another Epic',
          reference: 'foo&42',
        }),
      ).toBe('<li><small>foo&amp;42</small> Another Epic</li>');
    });
  });
});
