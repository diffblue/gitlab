import { getSelectedOptionsText } from 'ee/security_dashboard/components/shared/filters/utils';

describe('getSelectedOptionsText', () => {
  it('returns an empty string per default when no options are selected', () => {
    const options = [
      { id: 1, text: 'first' },
      { id: 2, text: 'second' },
    ];
    const selected = [];

    expect(getSelectedOptionsText(options, selected)).toBe('');
  });

  it('returns the provided placeholder when no options are selected', () => {
    const options = [
      { id: 1, text: 'first' },
      { id: 2, text: 'second' },
    ];
    const selected = [];

    expect(getSelectedOptionsText(options, selected, 'placeholder')).toBe('placeholder');
  });

  it('returns the text of the first selected option when only one option is selected', () => {
    const options = [{ id: 1, text: 'first' }];
    const selected = [options[0].id];

    expect(getSelectedOptionsText(options, selected)).toBe('first');
  });

  it.each`
    options                                                                            | expectedText
    ${[{ id: 1, text: 'first' }, { id: 2, text: 'second' }]}                           | ${'first +1 more'}
    ${[{ id: 1, text: 'first' }, { id: 2, text: 'second' }, { id: 3, text: 'third' }]} | ${'first +2 more'}
  `(
    'returns "$expectedText" when more than one option is selected',
    ({ options, expectedText }) => {
      const selected = options.map(({ id }) => id);

      expect(getSelectedOptionsText(options, selected)).toBe(expectedText);
    },
  );

  it('ignores selected options that are not in the options array', () => {
    const options = [
      { id: 1, text: 'first' },
      { id: 2, text: 'second' },
    ];
    const invalidOption = { id: 3, text: 'third' };
    const selected = [options[0].id, options[1].id, invalidOption.id];

    expect(getSelectedOptionsText(options, selected)).toBe('first +1 more');
  });
});
