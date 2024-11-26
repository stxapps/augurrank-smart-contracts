import { expect, it } from "vitest";
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get("wallet_2")!;
const wallet3 = accounts.get("wallet_3")!;

/*
  The test below is an example. To learn more, read the testing documentation here:
  https://docs.hiro.so/stacks/clarinet-js-sdk
*/

it("ensures simnet is well initalised", () => {
  expect(simnet.blockHeight).toBeDefined();
});

it("predict and verify", () => {
  simnet.mineEmptyBlocks(261238);

  let cRes;

  // first pred
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeOk(Cl.bool(true));
  const mh1 = simnet.blockHeight;

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet2);
  expect(cRes.result).toBeOk(Cl.bool(true));
  const mh2 = simnet.blockHeight;

  // invalid pred args
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('foo')], wallet3);
  expect(cRes.result).toBeErr(Cl.uint(100));

  simnet.mineEmptyBlocks(10);

  // premature verify
  cRes = simnet.callReadOnlyFn('augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(1)], wallet1);
  expect(cRes.result).toBeErr(Cl.uint(102));

  // invalid verify args
  cRes = simnet.callReadOnlyFn('augurrank-btc', 'verify', [Cl.address(wallet3), Cl.uint(1)], wallet1);
  expect(cRes.result).toBeErr(Cl.uint(100));

  // in anticipation
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeErr(Cl.uint(101));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet2);
  expect(cRes.result).toBeErr(Cl.uint(101));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet3);
  expect(cRes.result).toBeOk(Cl.bool(true));
  const mh3 = simnet.blockHeight;

  simnet.mineEmptyBlocks(2044);

  // first verify
  cRes = simnet.callReadOnlyFn('augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(1)], wallet1);
  expect(cRes.result).toBeOk(Cl.tuple({
    'anchor-height': Cl.uint(mh1),
    'target-height': Cl.uint(mh1 + 2048),
    'anchor-price': Cl.uint(0),
    'target-price': Cl.uint(0),
    value: Cl.stringAscii('down'),
    correct: Cl.bool(false),
  }));

  cRes = simnet.callReadOnlyFn('augurrank-btc', 'verify', [Cl.address(wallet2), Cl.uint(1)], wallet1);
  expect(cRes.result).toBeOk(Cl.tuple({
    'anchor-height': Cl.uint(mh2),
    'target-height': Cl.uint(mh2 + 2048),
    'anchor-price': Cl.uint(0),
    'target-price': Cl.uint(0),
    value: Cl.stringAscii('up'),
    correct: Cl.bool(false),
  }));

  cRes = simnet.callReadOnlyFn('augurrank-btc', 'verify', [Cl.address(wallet3), Cl.uint(1)], wallet2);
  expect(cRes.result).toBeErr(Cl.uint(102));

  // second pred
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeOk(Cl.bool(true));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet2);
  expect(cRes.result).toBeOk(Cl.bool(true));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet3);
  expect(cRes.result).toBeErr(Cl.uint(101));

  simnet.mineEmptyBlocks(256);

  // second verify
  cRes = simnet.callReadOnlyFn('augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(2)], wallet1);
  expect(cRes.result).toBeErr(Cl.uint(102));

  cRes = simnet.callReadOnlyFn('augurrank-btc', 'verify', [Cl.address(wallet3), Cl.uint(1)], wallet1);
  expect(cRes.result).toBeOk(Cl.tuple({
    'anchor-height': Cl.uint(mh3),
    'target-height': Cl.uint(mh3 + 2048),
    'anchor-price': Cl.uint(0),
    'target-price': Cl.uint(0),
    value: Cl.stringAscii('up'),
    correct: Cl.bool(false),
  }));

  simnet.mineEmptyBlocks(2048);

  // thrid pred
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeOk(Cl.bool(true));
});