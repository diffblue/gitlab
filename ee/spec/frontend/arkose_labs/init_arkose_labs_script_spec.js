import { initArkoseLabsScript } from 'ee/arkose_labs/init_arkose_labs_script';

jest.mock('lodash/uniqueId', () => () => 'initArkoseLabsScript_callback');

describe('initArkoseLabsScript', () => {
  let subject;

  const initSubject = () => {
    subject = initArkoseLabsScript({ publicKey: 'arkose-labs-public-api-key' });
  };

  const findScriptTags = () => document.querySelectorAll('script');

  afterEach(() => {
    subject = null;
    document.getElementsByTagName('html')[0].innerHTML = '';
  });

  it('sets a global enforcement callback', () => {
    initSubject();

    expect(window.initArkoseLabsScript_callback).not.toBe(undefined);
  });

  it('adds ArkoseLabs scripts to the HTML head', () => {
    expect(findScriptTags()).toHaveLength(0);

    initSubject();

    expect(findScriptTags()).toHaveLength(1);
  });

  it('when callback is called, cleans up the global object and resolves the Promise', () => {
    initSubject();
    const enforcement = 'ArkoseLabsEnforcement';
    window.initArkoseLabsScript_callback(enforcement);

    expect(window.initArkoseLabsScript_callback).toBe(undefined);
    return expect(subject).resolves.toBe(enforcement);
  });
});
