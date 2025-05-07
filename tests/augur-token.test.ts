import { expect, it } from 'vitest';
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const deployer = accounts.get('deployer')!;
const wallet1 = accounts.get('wallet_1')!;
const wallet2 = accounts.get('wallet_2')!;
const wallet3 = accounts.get('wallet_3')!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

it('ensures simnet is well initialised', () => {
  expect(simnet.blockHeight).toBeDefined();
});

it('allowed contracts', () => {
  let res;

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.principal(wallet2), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.principal(wallet1), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(deployer), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(1));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(deployer), Cl.none()],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callReadOnlyFn('augur-token', 'get-total-supply', [], wallet1);
  expect(res.result).toBeOk(Cl.uint(2000000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(deployer)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(1000000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet1)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(0));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet2)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(1000000));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.principal(wallet2), Cl.none()],
    wallet2
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.principal(wallet1), Cl.none()],
    wallet2
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(wallet2), Cl.principal(deployer), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [
      Cl.uint(100000),
      Cl.principal(deployer),
      Cl.principal(wallet1),
      Cl.some(Cl.bufferFromAscii('deployer transfers to wallet1.'))
    ],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'delete-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'delete-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'delete-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));
});

it('transfers', () => {
  let res, arg1;

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.principal(wallet2), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet1), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(deployer), Cl.none()],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callReadOnlyFn('augur-token', 'get-total-supply', [], wallet1);
  expect(res.result).toBeOk(Cl.uint(2000000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(deployer)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(1000000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet1)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(0));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet2)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(1000000));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(wallet2), Cl.principal(deployer), Cl.none()],
    wallet2
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(wallet2), Cl.principal(wallet1), Cl.none()],
    wallet2
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [
      Cl.uint(100000),
      Cl.principal(deployer),
      Cl.principal(wallet1),
      Cl.some(Cl.bufferFromAscii('deployer transfers to wallet1.'))
    ],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(wallet2), Cl.principal(deployer), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(wallet2), Cl.principal(wallet1), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-markets')],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-markets')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-store')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(deployer), Cl.principal(wallet1), Cl.none()],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(wallet2), Cl.principal(deployer), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'transfer',
    [Cl.uint(100000), Cl.principal(wallet2), Cl.principal(wallet1), Cl.none()],
    deployer
  );
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callReadOnlyFn('augur-token', 'get-total-supply', [], wallet3);
  expect(res.result).toBeOk(Cl.uint(2000000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(deployer)], wallet3
  );
  expect(res.result).toBeOk(Cl.uint(800000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet1)], wallet3
  );
  expect(res.result).toBeOk(Cl.uint(200000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet2)], wallet3
  );
  expect(res.result).toBeOk(Cl.uint(1000000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet3)], wallet3
  );
  expect(res.result).toBeOk(Cl.uint(0));

  res = simnet.callPublicFn(
    'augur-token',
    'burn',
    [Cl.uint(100000)],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'burn',
    [Cl.uint(100000)],
    wallet1
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'burn',
    [Cl.uint(100000)],
    wallet3
  );
  expect(res.result).toBeErr(Cl.uint(1));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.none()],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000000000000), Cl.principal(deployer), Cl.none()],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'mint',
    [Cl.uint(1000000), Cl.principal(wallet2), Cl.none()],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(deployer)], deployer
  );
  expect(res.result).toBeOk(Cl.uint(1000000000700000));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(wallet2)], deployer
  );
  expect(res.result).toBeOk(Cl.uint(2000000));

  arg1 = Cl.list([
    Cl.tuple({
      to: Cl.principal(wallet1),
      amount: Cl.uint(100000),
      memo: Cl.none(),
    }),
    Cl.tuple({
      to: Cl.principal(wallet2),
      amount: Cl.uint(100000),
      memo: Cl.some(Cl.bufferFromAscii('test2')),
    }),
    Cl.tuple({
      to: Cl.principal(wallet3),
      amount: Cl.uint(100000),
      memo: Cl.some(Cl.bufferFromAscii('test3')),
    }),
  ]);
  res = simnet.callPublicFn('augur-token', 'send-many', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn('augur-token', 'send-many', [arg1], deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callReadOnlyFn(
    'augur-token', 'get-balance', [Cl.principal(deployer)], wallet2
  );
  expect(res.result).toBeOk(Cl.uint(1000000000400000));

  arg1 = [
    Cl.uint(100000),
    Cl.principal(wallet1),
    Cl.principal(wallet2),
    Cl.some(Cl.bufferFromAscii('wallet1 transfers to wallet2.'))
  ];
  res = simnet.callPublicFn('augur-token', 'transfer', arg1, deployer);
  expect(res.result).toBeErr(Cl.uint(802));

  /*Doesn't work. Need to test call markets and markets call token.
  res = simnet.callPublicFn(
    'augur-token', 'transfer', arg1, deployer + '.augur-markets'
  );
  expect(res.result).toBeOk(Cl.bool(true));*/
});

it('read only', () => {
  let res;

  res = simnet.callReadOnlyFn('augur-token', 'get-name', [], wallet1);
  expect(res.result).toBeOk(Cl.stringAscii('Augur'));

  res = simnet.callReadOnlyFn('augur-token', 'get-symbol', [], wallet1);
  expect(res.result).toBeOk(Cl.stringAscii('AUG'));

  res = simnet.callReadOnlyFn('augur-token', 'get-decimals', [], wallet1);
  expect(res.result).toBeOk(Cl.uint(6));

  res = simnet.callReadOnlyFn('augur-token', 'get-total-supply', [], wallet1);
  expect(res.result).toBeOk(Cl.uint(0));

  res = simnet.callReadOnlyFn('augur-token', 'get-token-uri', [], wallet1);
  expect(res.result).toBeOk(Cl.none());

  res = simnet.callPublicFn(
    'augur-token',
    'set-token-uri',
    [Cl.stringUtf8('https://augurrank.com/token-metadata.json?source=test')],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn(
    'augur-token',
    'set-token-uri',
    [Cl.stringUtf8('https://augurrank.com/token-metadata.json?source=test')],
    deployer
  );
  //expect(res.result).toBeOk();

  res = simnet.callReadOnlyFn('augur-token', 'get-token-uri', [], wallet1);
  expect(res.result).toBeOk(Cl.some(Cl.stringUtf8(
    'https://augurrank.com/token-metadata.json?source=test'
  )));
});
