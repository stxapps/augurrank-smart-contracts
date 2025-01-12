import { expect, it } from "vitest";
import { Cl } from '@stacks/transactions';

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!; 
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
  simnet.mineEmptyBurnBlocks(261238);

  let cRes;

  // first pred
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeOk(Cl.tuple({ seq: Cl.uint(1) }));
  const [h1, bh1] = [simnet.blockHeight, simnet.burnBlockHeight];

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet2);
  expect(cRes.result).toBeOk(Cl.tuple({ seq: Cl.uint(1) }));
  const [h2, bh2] = [simnet.blockHeight, simnet.burnBlockHeight];

  // invalid pred args
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('foo')], wallet3);
  expect(cRes.result).toBeErr(Cl.uint(100));

  simnet.mineEmptyBurnBlocks(10);

  // premature verify
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(1), Cl.uint(h1 + 16)], deployer
  );
  expect(cRes.result).toBeErr(Cl.uint(103));

  // no pred to verify
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet3), Cl.uint(1), Cl.uint(1)], deployer
  );
  expect(cRes.result).toBeErr(Cl.uint(100));

  // in anticipation
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeErr(Cl.uint(101));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet2);
  expect(cRes.result).toBeErr(Cl.uint(101));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet3);
  expect(cRes.result).toBeOk(Cl.tuple({ seq: Cl.uint(1) }));
  const [h3, bh3] = [simnet.blockHeight, simnet.burnBlockHeight];

  simnet.mineEmptyBurnBlocks(96);

  // first verify
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(1), Cl.uint(h1 + 100)], deployer
  );
  expect(cRes.result).toBeOk(Cl.tuple({
    'anchor-height': Cl.uint(h1),
    'anchor-burn-height': Cl.uint(bh1),
    value: Cl.stringAscii('down'),
    'anchor-price': Cl.uint(0),
    'target-price': Cl.uint(0),
    correct: Cl.stringAscii('TRUE'),
  }));

  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet2), Cl.uint(1), Cl.uint(h2 + 100)], deployer
  );
  expect(cRes.result).toBeOk(Cl.tuple({
    'anchor-height': Cl.uint(h2),
    'anchor-burn-height': Cl.uint(bh2),
    value: Cl.stringAscii('up'),
    'anchor-price': Cl.uint(0),
    'target-price': Cl.uint(0),
    correct: Cl.stringAscii('TRUE'),
  }));

  // premature verify
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet3), Cl.uint(1), Cl.uint(h3 + 100)], deployer
  );
  expect(cRes.result).toBeErr(Cl.uint(103));

  // Caller must be admin
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(1), Cl.uint(h1 + 100)], wallet2
  );
  expect(cRes.result).toBeErr(Cl.uint(102));

  // Invalid height
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(1), Cl.uint(h1)], deployer
  );
  expect(cRes.result).toBeErr(Cl.uint(100));

  // second pred
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeOk(Cl.tuple({ seq: Cl.uint(2) }));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet2);
  expect(cRes.result).toBeOk(Cl.tuple({ seq: Cl.uint(2) }));

  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('up')], wallet3);
  expect(cRes.result).toBeErr(Cl.uint(101));

  simnet.mineEmptyBurnBlocks(56);

  // second verify
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet1), Cl.uint(2), Cl.uint(h1 + 96 + 100)], deployer
  );
  expect(cRes.result).toBeErr(Cl.uint(103));

  cRes = simnet.callPublicFn(
    'augurrank-btc', 'verify', [Cl.address(wallet3), Cl.uint(1), Cl.uint(h3 + 100)], deployer
  );
  expect(cRes.result).toBeOk(Cl.tuple({
    'anchor-height': Cl.uint(h3),
    'anchor-burn-height': Cl.uint(bh3),
    value: Cl.stringAscii('up'),
    'anchor-price': Cl.uint(0),
    'target-price': Cl.uint(0),
    correct: Cl.stringAscii('TRUE'),
  }));

  simnet.mineEmptyBlocks(2048);

  // thrid pred
  cRes = simnet.callPublicFn('augurrank-btc', 'predict', [Cl.stringAscii('down')], wallet1);
  expect(cRes.result).toBeOk(Cl.tuple({ seq: Cl.uint(3) }));

  // n/a
  cRes = simnet.callPublicFn(
    'augurrank-btc', 'not-available', [Cl.address(wallet1), Cl.uint(2)], wallet2
  );
  expect(cRes.result).toBeErr(Cl.uint(102));

  cRes = simnet.callPublicFn(
    'augurrank-btc', 'not-available', [Cl.address(wallet1), Cl.uint(99)], deployer
  );
  expect(cRes.result).toBeErr(Cl.uint(100));

  cRes = simnet.callPublicFn(
    'augurrank-btc', 'not-available', [Cl.address(wallet1), Cl.uint(3)], deployer
  );
  expect(cRes.result).toBeOk(Cl.tuple({ correct: Cl.stringAscii('N/A') }));
});
