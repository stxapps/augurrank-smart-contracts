import { expect, it } from 'vitest';
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const deployer = accounts.get('deployer')!;
const wallet1 = accounts.get('wallet_1')!;
const wallet2 = accounts.get('wallet_2')!;
const wallet3 = accounts.get('wallet_3')!;
const wallet4 = accounts.get('wallet_4')!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

it('ensures simnet is well initialised', () => {
  expect(simnet.blockHeight).toBeDefined();
});

it('event', () => {
  let res, arg1, arg2;

  arg1 = [
    Cl.stringAscii('Will Stacks be ok?'),
    Cl.stringAscii('This is a description.'),
    Cl.uint(300000000),
    Cl.uint(0),
    Cl.none(),
    Cl.list([
      Cl.tuple({ desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(0) }),
    ]),
  ];
  res = simnet.callPublicFn('augur-markets', 'create-event', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(801));

  res = simnet.callPublicFn('augur-markets', 'create-event', arg1, deployer);
  expect(res.result).toBeOk(Cl.uint(0));

  res = simnet.callPublicFn('augur-markets', 'create-event', arg1, deployer);
  expect(res.result).toBeOk(Cl.uint(1));

  arg1 = [Cl.uint(0), Cl.uint(400000000)];
  res = simnet.callPublicFn('augur-markets', 'set-event-beta', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(801));

  arg1 = [Cl.uint(2), Cl.uint(400000000)];
  res = simnet.callPublicFn('augur-markets', 'set-event-beta', arg1, deployer);
  expect(res.result).toBeErr(Cl.uint(811));

  arg1 = [Cl.uint(0), Cl.uint(400000000)];
  res = simnet.callPublicFn('augur-markets', 'set-event-beta', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(1), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'set-event-beta', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(1), Cl.none()];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(801));

  arg1 = [Cl.uint(2), Cl.uint(1), Cl.none()];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeErr(Cl.uint(811));

  arg1 = [Cl.uint(0), Cl.uint(1), Cl.none()];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.none()];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeErr(Cl.uint(821));

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.some(Cl.uint(1))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-markets',
    'buy-shares-a',
    [Cl.uint(1), Cl.uint(1), Cl.uint(1000000), Cl.uint(800000)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(831));

  arg1 = [Cl.uint(0), Cl.uint(1), Cl.none()];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(1), Cl.uint(1000000), Cl.uint(900000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(843));

  arg2 = [Cl.uint(1000000000), Cl.principal(wallet1), Cl.none()];
  res = simnet.callPublicFn('augur-token', 'mint', arg2, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(802));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-markets')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000), cost: Cl.uint(636400),
  }));

  res = simnet.callPublicFn(
    'augur-markets',
    'buy-shares-a',
    [Cl.uint(0), Cl.uint(1), Cl.uint(1000000), Cl.uint(10000)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(841));

  /* Run-time error: unwrap-panic on invalid outcome-id
  res = simnet.callPublicFn(
    'augur-markets',
    'buy-shares-a',
    [Cl.uint(0), Cl.uint(2), Cl.uint(1000000), Cl.uint(800000)],
    wallet1
  );
  expect(res.result).toBeErr();*/

  res = simnet.callPublicFn(
    'augur-markets',
    'buy-shares-a',
    [Cl.uint(0), Cl.uint(1), Cl.uint(1), Cl.uint(1000000)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(822));

  arg2 = [Cl.uint(1000000000), Cl.principal(wallet2), Cl.none()];
  res = simnet.callPublicFn('augur-token', 'mint', arg2, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(9000000), Cl.uint(8000000), Cl.uint(300000)]
  res = simnet.callPublicFn('augur-markets', 'buy-shares-b', arg1, wallet2);
  expect(res.result).toBeErr(Cl.uint(841));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(2000000), Cl.uint(1000000), Cl.uint(900000)]
  res = simnet.callPublicFn('augur-markets', 'buy-shares-b', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000), cost: Cl.uint(636400),
  }));

  arg1 = [Cl.uint(0), Cl.list([Cl.uint(0), Cl.uint(1)])];
  res = simnet.callReadOnlyFn('augur-markets', 'get-b-and-ocs', arg1, wallet1);
  expect(res.result).toBeTuple({
    beta: Cl.uint(400000000),
    ocs: Cl.list([
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(1000000),
      })),
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(1000000),
      })),
    ]),
  });

  arg1 = [Cl.uint(0)];
  res = simnet.callReadOnlyFn('augur-markets', 'get-share-amounts', arg1, wallet1);
  expect(res.result).toBeTuple({
    amounts: Cl.list([Cl.uint(1000000), Cl.uint(1000000)]),
  });

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(1000000), qb: Cl.uint(2500) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(1000000), qb: Cl.uint(2500) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(400000000), Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(268458400);

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(101000000), qb: Cl.uint(252500) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(1000000), qb: Cl.uint(2500) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(400000000), Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(332122400);

  arg1 = [
    Cl.uint(0), Cl.uint(0),
    Cl.uint(200000000), Cl.uint(150000000), Cl.uint(100000000), Cl.uint(90000000),
  ]
  res = simnet.callPublicFn('augur-markets', 'buy-shares-c', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(63664000),
  }));

  arg1 = [Cl.uint(1), Cl.uint(0), Cl.uint(1000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet2);
  expect(res.result).toBeErr(Cl.uint(831));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(1000123), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet2);
  expect(res.result).toBeErr(Cl.uint(822));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(1000000), Cl.uint(200000000)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet2);
  expect(res.result).toBeErr(Cl.uint(842));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(10000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet2);
  expect(res.result).toBeErr(Cl.uint(844));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(1000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000), cost: Cl.uint(636800),
  }));

  arg1 = [Cl.uint(0), Cl.list([Cl.uint(0), Cl.uint(1), Cl.uint(2), Cl.uint(3)])];
  res = simnet.callReadOnlyFn('augur-markets', 'get-b-and-ocs', arg1, wallet1);
  expect(res.result).toBeTuple({
    beta: Cl.uint(400000000),
    ocs: Cl.list([
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(100000000),
      })),
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(1000000),
      })),
      Cl.none(),
      Cl.none(),
    ]),
  });

  res = simnet.callReadOnlyFn('augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1);
  expect(res.result).toBeList([Cl.uint(568980), Cl.uint(431019)]);

  arg1 = [Cl.uint(0)];
  res = simnet.callReadOnlyFn('augur-markets', 'get-share-amounts', arg1, wallet1);
  expect(res.result).toBeTuple({
    amounts: Cl.list([Cl.uint(100000000), Cl.uint(1000000)]),
  });

  arg1 = [Cl.principal(wallet1)];
  res = simnet.callReadOnlyFn('augur-markets', 'get-balance', arg1, wallet1);
  expect(res.result).toBeOk(Cl.uint(935699600));

  arg1 = [Cl.principal(wallet2)];
  res = simnet.callReadOnlyFn('augur-markets', 'get-balance', arg1, wallet1);
  expect(res.result).toBeOk(Cl.uint(1000000400));

  arg1 = [Cl.uint(0), Cl.uint(1), Cl.uint(100000000), Cl.uint(0), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-b', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(844));

  arg1 = [Cl.uint(0), Cl.uint(1), Cl.uint(0), Cl.uint(0), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-b', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(822));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(1000000), Cl.uint(2000000), Cl.uint(10000000)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-b', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(842));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(1000000), Cl.uint(6000000), Cl.uint(3000000)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-b', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(6000000), cost: Cl.uint(3820000),
  }));

  arg1 = [
    Cl.uint(0), Cl.uint(0),
    Cl.uint(1000000), Cl.uint(2000000), Cl.uint(10000000), Cl.uint(4000000),
  ];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-c', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(10000000), cost: Cl.uint(6366400),
  }));

  res = simnet.callPublicFn('augur-markets', 'claim-reward', [Cl.uint(3)], wallet1);
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn('augur-markets', 'claim-reward', [Cl.uint(0)], wallet1);
  expect(res.result).toBeErr(Cl.uint(815));

  arg1 = [Cl.uint(0), Cl.uint(5), Cl.some(Cl.uint(1))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'claim-reward', [Cl.uint(0)], wallet1);
  expect(res.result).toBeErr(Cl.uint(832));

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.some(Cl.uint(1))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'claim-reward', [Cl.uint(0)], wallet1);
  expect(res.result).toBeOk(Cl.tuple({ reward: Cl.uint(1000000) }));

  res = simnet.callPublicFn('augur-markets', 'claim-reward', [Cl.uint(0)], wallet1);
  expect(res.result).toBeErr(Cl.uint(845));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet1) }),
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet2) }),
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet3) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(845));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet2) }),
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet3) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(813));
});

const init = () => {
  let res, arg1;

  arg1 = [Cl.uint(1000000000000), Cl.principal(deployer), Cl.none()];
  res = simnet.callPublicFn('augur-token', 'mint', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(1000000000), Cl.principal(wallet1), Cl.none()];
  res = simnet.callPublicFn('augur-token', 'mint', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1[1] = Cl.principal(wallet2);
  res = simnet.callPublicFn('augur-token', 'mint', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1[1] = Cl.principal(wallet3);
  res = simnet.callPublicFn('augur-token', 'mint', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1[1] = Cl.principal(wallet4);
  res = simnet.callPublicFn('augur-token', 'mint', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-markets')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'delete-allowed-contract',
    [Cl.principal(deployer + '.augur-markets')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn(
    'augur-token',
    'add-allowed-contract',
    [Cl.principal(deployer + '.augur-markets')],
    deployer
  );
  expect(res.result).toBeOk(Cl.bool(true));
};

it('rewards', () => {
  let res, arg1;

  init();

  arg1 = [
    Cl.stringAscii('Will Stacks be ok?'),
    Cl.stringAscii(''),
    Cl.uint(300000000),
    Cl.uint(1),
    Cl.none(),
    Cl.list([
      Cl.tuple({ desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('Not sure'), 'share-amount': Cl.uint(0) }),
    ]),
  ];
  res = simnet.callPublicFn('augur-markets', 'create-event', arg1, deployer);
  expect(res.result).toBeOk(Cl.uint(0));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(100000000), Cl.uint(100000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(39969600),
  }));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(100000000), Cl.uint(100000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(52934100),
  }));

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.uint(1000000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet3);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000000), cost: Cl.uint(615390300),
  }));

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.some(Cl.uint(2))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet3) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(832));

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.some(Cl.uint(2))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet1) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(813));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet3) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(845));

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.some(Cl.uint(0))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet1) }),
    Cl.tuple({ 'event-id': Cl.uint(0), 'user-id': Cl.principal(wallet2) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'pay-rewards', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(845));
});

it('claim refund', () => {
  let res, arg1;

  init();

  arg1 = [
    Cl.stringAscii('Will Stacks be ok?'),
    Cl.stringAscii(''),
    Cl.uint(300000000),
    Cl.uint(1),
    Cl.none(),
    Cl.list([
      Cl.tuple({ desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('Not sure'), 'share-amount': Cl.uint(0) }),
    ]),
  ];
  res = simnet.callPublicFn('augur-markets', 'create-event', arg1, deployer);
  expect(res.result).toBeOk(Cl.uint(0));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(100000000), Cl.uint(100000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(39969600),
  }));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(100000000), Cl.uint(100000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(52934100),
  }));

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.uint(1000000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet3);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000000), cost: Cl.uint(615390300),
  }));

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.some(Cl.uint(2))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(2)];
  res = simnet.callPublicFn('augur-markets', 'claim-refund', arg1, wallet3);
  expect(res.result).toBeErr(Cl.uint(833));

  arg1 = [Cl.uint(0), Cl.uint(6), Cl.none()];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(2)];
  res = simnet.callPublicFn('augur-markets', 'claim-refund', arg1, wallet3);
  expect(res.result).toBeOk(Cl.tuple({ fund: Cl.uint(1000000000) }));

  arg1 = [Cl.uint(0), Cl.uint(2)];
  res = simnet.callPublicFn('augur-markets', 'claim-refund', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(813));

  arg1 = [Cl.uint(2), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'claim-refund', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(811));

  arg1 = [Cl.uint(0), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'claim-refund', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({ fund: Cl.uint(100000000) }));

  res = simnet.callPublicFn('augur-markets', 'claim-refund', arg1, wallet1);
  expect(res.result).toBeErr(Cl.uint(845));
});

it('refund', () => {
  let res, arg1;

  init();

  arg1 = [
    Cl.stringAscii('Will Stacks be ok?'),
    Cl.stringAscii(''),
    Cl.uint(300000000),
    Cl.uint(1),
    Cl.none(),
    Cl.list([
      Cl.tuple({ desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('Not sure'), 'share-amount': Cl.uint(0) }),
    ]),
  ];
  res = simnet.callPublicFn('augur-markets', 'create-event', arg1, deployer);
  expect(res.result).toBeOk(Cl.uint(0));

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(0), qb: Cl.uint(0) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(0), qb: Cl.uint(0) }),
    Cl.tuple({ id: Cl.uint(2), q: Cl.uint(0), qb: Cl.uint(0) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(300000000), Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(321954900);

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(100000000), qb: Cl.uint(333333) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(0), qb: Cl.uint(0) }),
    Cl.tuple({ id: Cl.uint(2), q: Cl.uint(0), qb: Cl.uint(0) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(300000000), Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(361924500);

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(100000000), Cl.uint(100000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(39969600),
  }));

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(100000000), Cl.uint(100000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(52934100),
  }));

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.uint(1000000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet3);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000000), cost: Cl.uint(615390300),
  }));

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.some(Cl.uint(2))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'outcome-id': Cl.uint(2), 'user-id': Cl.principal(wallet3) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'refund-funds', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(833));

  arg1 = [Cl.uint(0), Cl.uint(6), Cl.none()];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'outcome-id': Cl.uint(2), 'user-id': Cl.principal(wallet1) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'refund-funds', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(813));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'outcome-id': Cl.uint(2), 'user-id': Cl.principal(wallet3) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'refund-funds', [arg1], wallet1);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'refund-funds', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(845));

  arg1 = [Cl.uint(0), Cl.uint(6), Cl.some(Cl.uint(0))];
  res = simnet.callPublicFn('augur-markets', 'set-event-status', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = Cl.list([
    Cl.tuple({ 'event-id': Cl.uint(0), 'outcome-id': Cl.uint(0), 'user-id': Cl.principal(wallet1) }),
    Cl.tuple({ 'event-id': Cl.uint(0), 'outcome-id': Cl.uint(0), 'user-id': Cl.principal(wallet2) }),
  ]);
  res = simnet.callPublicFn('augur-markets', 'refund-funds', [arg1], wallet1);
  expect(res.result).toBeOk(Cl.bool(true));

  res = simnet.callPublicFn('augur-markets', 'refund-funds', [arg1], wallet1);
  expect(res.result).toBeErr(Cl.uint(845));
});

it('no event', () => {
  let res;

  res = simnet.callPublicFn(
    'augur-markets',
    'buy-shares-a',
    [Cl.uint(1), Cl.uint(1), Cl.uint(1000000), Cl.uint(800000)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'buy-shares-b',
    [Cl.uint(1), Cl.uint(1), Cl.uint(2000000), Cl.uint(1000000), Cl.uint(800000)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'buy-shares-c',
    [
      Cl.uint(1), Cl.uint(1), Cl.uint(3000000), Cl.uint(2000000), Cl.uint(1000000),
      Cl.uint(800000),
    ],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'sell-shares-a',
    [Cl.uint(1), Cl.uint(1), Cl.uint(1000000), Cl.uint(200000)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'sell-shares-b',
    [Cl.uint(1), Cl.uint(1), Cl.uint(2000000), Cl.uint(1000000), Cl.uint(200000)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'sell-shares-c',
    [
      Cl.uint(1), Cl.uint(1), Cl.uint(3000000), Cl.uint(2000000), Cl.uint(1000000),
      Cl.uint(200000),
    ],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'claim-reward',
    [Cl.uint(1)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'pay-reward',
    [Cl.tuple({ 'event-id': Cl.uint(1), 'user-id': Cl.principal(wallet2) })],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'pay-rewards',
    [Cl.list([
      Cl.tuple({ 'event-id': Cl.uint(1), 'user-id': Cl.principal(wallet2) })
    ])],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'claim-refund',
    [Cl.uint(1), Cl.uint(1)],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'refund-fund',
    [Cl.tuple({
      'event-id': Cl.uint(1),
      'outcome-id': Cl.uint(1),
      'user-id': Cl.principal(wallet2),
    })],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));

  res = simnet.callPublicFn(
    'augur-markets',
    'refund-funds',
    [Cl.list([
      Cl.tuple({
        'event-id': Cl.uint(1),
        'outcome-id': Cl.uint(1),
        'user-id': Cl.principal(wallet2),
      })
    ])],
    wallet1
  );
  expect(res.result).toBeErr(Cl.uint(811));
});

it('prices', () => {
  let res, arg1;

  init();

  arg1 = [
    Cl.stringAscii('Will Stacks be ok?'),
    Cl.stringAscii(''),
    Cl.uint(300000000),
    Cl.uint(1),
    Cl.none(),
    Cl.list([
      Cl.tuple({ desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('Not sure'), 'share-amount': Cl.uint(0) }),
      Cl.tuple({ desc: Cl.stringAscii('Dont care'), 'share-amount': Cl.uint(0) }),
    ]),
  ];
  res = simnet.callPublicFn('augur-markets', 'create-event', arg1, deployer);
  expect(res.result).toBeOk(Cl.uint(0));

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.uint(50000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(50000000), cost: Cl.uint(15425100),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(237178), Cl.uint(237178), Cl.uint(288465), Cl.uint(237178),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.uint(40000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(40000000), cost: Cl.uint(10058700),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(227830), Cl.uint(227830), Cl.uint(316509), Cl.uint(227830),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(1000000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet3);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000000), cost: Cl.uint(593875800),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(31093), Cl.uint(31093), Cl.uint(43195), Cl.uint(894617),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.uint(40000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(40000000), cost: Cl.uint(1570200),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(31261), Cl.uint(31261), Cl.uint(38021), Cl.uint(899456),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(50000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(50000000), cost: Cl.uint(1962600),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(37765), Cl.uint(31051), Cl.uint(37765), Cl.uint(893416),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(100000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet3);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(100000000), cost: Cl.uint(95490000),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(27825), Cl.uint(22878), Cl.uint(27825), Cl.uint(921469),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(1000000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet4);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000000), cost: Cl.uint(939336900),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(1105), Cl.uint(909), Cl.uint(1105), Cl.uint(996879),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(0), Cl.uint(50000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(50000000), cost: Cl.uint(59100),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(909), Cl.uint(909), Cl.uint(1105), Cl.uint(997075),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(2), Cl.uint(50000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(50000000), cost: Cl.uint(58800)
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(909), Cl.uint(909), Cl.uint(909), Cl.uint(997271),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(991000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(991000000), cost: Cl.uint(991000000),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(29), Cl.uint(29), Cl.uint(29), Cl.uint(999910),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(800000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(800000000), cost: Cl.uint(784287300),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(2), Cl.uint(2), Cl.uint(2), Cl.uint(999993),
  ]);

  arg1 = [Cl.uint(0), Cl.list([Cl.uint(0), Cl.uint(1), Cl.uint(2), Cl.uint(3)])];
  res = simnet.callReadOnlyFn('augur-markets', 'get-b-and-ocs', arg1, wallet1);
  expect(res.result).toBeTuple({
    beta: Cl.uint(300000000),
    ocs: Cl.list([
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('Yes'), 'share-amount': Cl.uint(0),
      })),
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('No'), 'share-amount': Cl.uint(0),
      })),
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('Not sure'), 'share-amount': Cl.uint(0),
      })),
      Cl.some(Cl.tuple({
        desc: Cl.stringAscii('Dont care'), 'share-amount': Cl.uint(3891000000),
      })),
    ]),
  });

  arg1 = [Cl.uint(0)];
  res = simnet.callReadOnlyFn('augur-markets', 'get-share-amounts', arg1, wallet1);
  expect(res.result).toBeTuple({
    amounts: Cl.list([Cl.uint(0), Cl.uint(0), Cl.uint(0), Cl.uint(3891000000)]),
  });

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(3900000000), qb: Cl.uint(13000000) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(300000000), Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(3899023500);

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(2900000000), qb: Cl.uint(9666666) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(300000000), Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(2897131800);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(1000000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet4);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000000), cost: Cl.uint(1000000000),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(58), Cl.uint(58), Cl.uint(58), Cl.uint(999823),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(1100000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet3);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1100000000), cost: Cl.uint(1100000000),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(2507), Cl.uint(2507), Cl.uint(2507), Cl.uint(992477),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(991000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(991000000), cost: Cl.uint(906683400)
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(56126), Cl.uint(56126), Cl.uint(56126), Cl.uint(831619),
  ]);

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(800000000), Cl.uint(0)];
  res = simnet.callPublicFn('augur-markets', 'sell-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(800000000), cost: Cl.uint(444535200),
  }));

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-share-costs', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeList([
    Cl.uint(250000), Cl.uint(250000), Cl.uint(250000), Cl.uint(250000),
  ]);

  arg1 = [Cl.uint(1000000000), Cl.principal(wallet1), Cl.none()];
  res = simnet.callPublicFn('augur-token', 'mint', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(10000000000)];
  res = simnet.callPublicFn('augur-markets', 'set-event-beta', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(1000000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet1);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(1000000000), cost: Cl.uint(346530000),
  }));

  arg1 = [Cl.uint(0), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'set-event-beta', arg1, deployer);
  expect(res.result).toBeOk(Cl.bool(true));

  arg1 = [Cl.uint(0), Cl.uint(3), Cl.uint(991000000), Cl.uint(1000000000)];
  res = simnet.callPublicFn('augur-markets', 'buy-shares-a', arg1, wallet2);
  expect(res.result).toBeOk(Cl.tuple({
    amount: Cl.uint(991000000), cost: Cl.uint(611857000),
  }));
});

it('LMSR', () => {
  let res, arg1, arg2;

  arg1 = { id: Cl.uint(2), q: Cl.uint(400000000), qb: Cl.uint(498343) };
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-exp-qb', [Cl.tuple(arg1)], wallet1
  );
  expect(res.result).toBeUint(1646571);

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(77), qb: Cl.uint(498343) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(77), qb: Cl.uint(1984321) }),
    Cl.tuple({ id: Cl.uint(2), q: Cl.uint(77), qb: Cl.uint(99999999) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-sum-exp', [Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(10686474581533407457n);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(1234567), Cl.list(arg1)], wallet1
  );
  expect(res.result).toBeUint(33260809);

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(100000000), qb: Cl.uint(333333) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(88000000), qb: Cl.uint(293333) }),
    Cl.tuple({ id: Cl.uint(2), q: Cl.uint(175000000), qb: Cl.uint(583333) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-delta-cost',
    [Cl.uint(300000000), Cl.list(arg1), Cl.uint(1), Cl.bool(true), Cl.uint(2000000)],
    wallet1
  );
  expect(res.result).toBeUint(503100);

  arg2 = [...arg1];
  arg2[1] = Cl.tuple({ id: Cl.uint(1), q: Cl.uint(90000000), qb: Cl.uint(300000) });
  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-delta-cost',
    [Cl.uint(300000000), Cl.list(arg2), Cl.uint(1), Cl.bool(false), Cl.uint(2000000)],
    wallet1
  );
  expect(res.result).toBeUint(503100);

  arg2 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(0), qb: Cl.uint(333333) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(0), qb: Cl.uint(293333) }),
    Cl.tuple({ id: Cl.uint(2), q: Cl.uint(0), qb: Cl.uint(583333) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(300000000), Cl.list(arg2)], wallet1
  );
  expect(res.result).toBeUint(454441800);

  arg2 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(0), qb: Cl.uint(333333) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(0), qb: Cl.uint(293333) }),
    Cl.tuple({ id: Cl.uint(2), q: Cl.uint(0), qb: Cl.uint(283333) }),
  ];
  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-cost', [Cl.uint(300000000), Cl.list(arg2)], wallet1
  );
  expect(res.result).toBeUint(427731300);

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-delta-cost',
    [Cl.uint(300000000), Cl.list(arg1), Cl.uint(2), Cl.bool(false), Cl.uint(90000000)],
    wallet1
  );
  expect(res.result).toBeUint(26710500);

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-share-cost',
    [Cl.uint(4640042), arg1[0]],
    wallet1
  );
  expect(res.result).toBeUint(308721);

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-share-cost',
    [Cl.uint(4640042), arg1[1]],
    wallet1
  );
  expect(res.result).toBeUint(297536);

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-share-cost',
    [Cl.uint(4640042), arg1[2]],
    wallet1
  );
  expect(res.result).toBeUint(393742);
});

it('read helpers', () => {
  let res, arg1, arg2;

  res = simnet.callReadOnlyFn(
    'augur-markets', 'is-amount-valid', [Cl.uint(0)], wallet1
  );
  expect(res.result).toBeBool(false);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'is-amount-valid', [Cl.uint(1)], wallet1
  );
  expect(res.result).toBeBool(false);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'is-amount-valid', [Cl.uint(23000000)], wallet1
  );
  expect(res.result).toBeBool(true);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'is-amount-valid', [Cl.uint(23000001)], wallet1
  );
  expect(res.result).toBeBool(false);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-event', [Cl.uint(90)], wallet1
  );
  expect(res.result).toBeNone();

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-outcome', [Cl.uint(90), Cl.uint(9)], wallet1
  );
  expect(res.result).toBeNone();

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-user',
    [Cl.uint(90), Cl.uint(9), Cl.principal(wallet2)],
    wallet1
  );
  expect(res.result).toBeNone();

  res = simnet.callReadOnlyFn(
    'augur-markets', 'get-balance', [Cl.principal(wallet2)], wallet1
  );
  expect(res.result).toBeOk(Cl.uint(0));

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'is-some-outcome',
    [Cl.some(Cl.tuple({
      desc: Cl.stringAscii('test'), 'share-amount': Cl.uint(2000000),
    }))],
    wallet1
  );
  expect(res.result).toBeBool(true);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'is-some-outcome', [Cl.none()], wallet1
  );
  expect(res.result).toBeBool(false);

  arg1 = {
    desc: Cl.stringAscii('test'), 'share-amount': Cl.uint(2000000),
  };
  res = simnet.callReadOnlyFn(
    'augur-markets',
    'unwrap-panic-outcome',
    [Cl.some(Cl.tuple(arg1))],
    wallet1
  );
  expect(res.result).toBeTuple(arg1);

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-qqb',
    [Cl.uint(22), Cl.tuple(arg1), Cl.uint(98)],
    wallet1
  );
  expect(res.result).toBeTuple({
    id: Cl.uint(22), q: Cl.uint(2000000), qb: Cl.uint(20408163265),
  });

  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-qqbs',
    [Cl.uint(22), Cl.uint(98)],
    wallet1
  );
  expect(res.result).toBeList([]);

  arg1 = { id: Cl.uint(8), q: Cl.uint(77), qb: Cl.uint(999) };
  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-new-qqb',
    [Cl.tuple(arg1)],
    wallet1
  );
  expect(res.result).toBeTuple(arg1);

  arg1 = [
    Cl.tuple({ id: Cl.uint(0), q: Cl.uint(77), qb: Cl.uint(999) }),
    Cl.tuple({ id: Cl.uint(1), q: Cl.uint(77), qb: Cl.uint(999) }),
    Cl.tuple({ id: Cl.uint(2), q: Cl.uint(77), qb: Cl.uint(999) }),
  ];
  arg2 = [...arg1];
  arg2[1] = Cl.tuple({ id: Cl.uint(1), q: Cl.uint(78), qb: Cl.uint(26) });
  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-new-qqbs',
    [Cl.uint(2987123), Cl.list(arg1), Cl.uint(1), Cl.bool(true), Cl.uint(1)],
    wallet1
  );
  expect(res.result).toBeList(arg2);

  arg2 = [...arg1];
  arg2[2] = Cl.tuple({ id: Cl.uint(2), q: Cl.uint(76), qb: Cl.uint(2620689) });
  res = simnet.callReadOnlyFn(
    'augur-markets',
    'get-new-qqbs',
    [Cl.uint(29), Cl.list(arg1), Cl.uint(2), Cl.bool(false), Cl.uint(1)],
    wallet1
  );
  expect(res.result).toBeList(arg2);
});

it('perform helpers', () => {
  let res;

  res = simnet.callPrivateFn(
    'augur-markets',
    'insert-outcome',
    [
      Cl.uint(12),
      Cl.uint(3),
      Cl.tuple({ desc: Cl.stringAscii('Test test'), 'share-amount': Cl.uint(4000000) })
    ],
    wallet1
  );
  expect(res.result).toBeBool(true);
});

it('exp()', () => {
  let res;

  res = simnet.callReadOnlyFn('augur-markets', 'exp', [Cl.uint(0)], wallet1);
  expect(res.result).toBeUint(1000000);

  res = simnet.callReadOnlyFn('augur-markets', 'exp', [Cl.uint(123)], wallet1);
  expect(res.result).toBeUint(1000159);

  res = simnet.callReadOnlyFn('augur-markets', 'exp', [Cl.uint(1000000)], wallet1);
  expect(res.result).toBeUint(2718281);

  res = simnet.callReadOnlyFn('augur-markets', 'exp', [Cl.uint(1234567)], wallet1);
  expect(res.result).toBeUint(3545555);

  res = simnet.callReadOnlyFn('augur-markets', 'exp', [Cl.uint(23456789)], wallet1);
  expect(res.result).toBeUint(17393424033409381n);

  res = simnet.callReadOnlyFn('augur-markets', 'exp', [Cl.uint(123456789)], wallet1);
  expect(res.result).toBeUint(10686474581524463000n);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'exp', [Cl.uint(1234567890123)], wallet1
  );
  expect(res.result).toBeUint(10686474581524463000n);

  res = simnet.callReadOnlyFn(
    'augur-markets', 'exp', [Cl.uint(123456789012345)], wallet1
  );
  expect(res.result).toBeUint(10686474581524463000n);
});

it('ln()', () => {
  let res;

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(0)], wallet1);
  expect(res.result).toBeUint(0);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(123)], wallet1);
  expect(res.result).toBeUint(0);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(1000000)], wallet1);
  expect(res.result).toBeUint(0);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(1234567)], wallet1);
  expect(res.result).toBeUint(182957);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(123456789)], wallet1);
  expect(res.result).toBeUint(4757803);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(1234567890123)], wallet1);
  expect(res.result).toBeUint(13992972);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(1234567890123456)], wallet1);
  expect(res.result).toBeUint(20827382);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(123456789012345678n)], wallet1);
  expect(res.result).toBeUint(25433510);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(12345678901234567890n)], wallet1);
  expect(res.result).toBeUint(26941275);

  res = simnet.callReadOnlyFn('augur-markets', 'ln', [Cl.uint(1234567890123456789012n)], wallet1);
  expect(res.result).toBeUint(26941275);
});
