import * as Utils from 'ee/status_checks/utils';

describe('modalPrimaryActionProps', () => {
  it('returns the props with the text and loading state', () => {
    const text = 'Button text';
    const loading = true;

    expect(Utils.modalPrimaryActionProps(text, loading)).toStrictEqual({
      text,
      attributes: { variant: 'confirm', loading },
    });
  });
});
