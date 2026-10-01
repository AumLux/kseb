begin;
\ir fixtures/org.psql
select plan(13);

insert into public.material_catalog (id, code, name, category, unit, reorder_level)
values ('90000000-0000-0000-0000-000000000001', 'T-ACSR-RAB', 'ACSR Rabbit conductor', 'Conductor', 'm', 50);
insert into public.stores (id, section_id, name)
values ('91000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-00000000000a', 'Section A store');

-- W1 asks to issue 30 m from an empty store; approval fails on stock.
select tests.login('a0000000-0000-0000-0000-000000000001');
select lives_ok($$
  insert into public.material_requests (id, request_type, material_id, store_id, quantity, purpose)
  values ('92000000-0000-0000-0000-000000000001', 'issue', '90000000-0000-0000-0000-000000000001',
          '91000000-0000-0000-0000-000000000001', 30, 'Re-stringing span 14-15')$$,
  'staff can raise an issue request');
select throws_ok(
  $$insert into public.stock_ledger (material_id, store_id, qty_delta, txn_type)
    values ('90000000-0000-0000-0000-000000000001', '91000000-0000-0000-0000-000000000001', 1000, 'receipt')$$,
  '42501', null, 'nobody can post stock directly');
select throws_like(
  $$select public.decide_material_request('92000000-0000-0000-0000-000000000001', true)$$,
  '%higher authority%', 'staff cannot approve');
reset role;

select tests.login('f0000000-0000-0000-0000-000000000001');
select throws_like(
  $$select public.decide_material_request('92000000-0000-0000-0000-000000000001', true)$$,
  '%Not enough stock%', 'approval cannot drive stock negative');
-- Supervisor receives 100 m; the manager approves.
select lives_ok($$
  insert into public.material_requests (id, request_type, material_id, store_id, quantity, unit_price, supplier, purpose)
  values ('92000000-0000-0000-0000-000000000002', 'receipt', '90000000-0000-0000-0000-000000000001',
          '91000000-0000-0000-0000-000000000001', 100, 45.50, 'Kerala Cables Ltd', 'PO 2026/77 delivery')$$,
  'supervisor can raise a receipt');
select throws_like(
  $$select public.decide_material_request('92000000-0000-0000-0000-000000000002', true)$$,
  '%higher authority%', 'no self-approval');
reset role;

select tests.login('e0000000-0000-0000-0000-000000000001');
select lives_ok($$select public.decide_material_request('92000000-0000-0000-0000-000000000002', true)$$,
  'manager approves the receipt');
select is((select on_hand from public.stock_balances), 100.000::numeric(14, 3), 'stock is 100 after the receipt');
reset role;

select tests.login('f0000000-0000-0000-0000-000000000001');
select lives_ok($$select public.decide_material_request('92000000-0000-0000-0000-000000000001', true)$$,
  'the issue can now be approved');
select throws_like(
  $$select public.decide_material_request('92000000-0000-0000-0000-000000000001', true)$$,
  '%already approved%', 'replaying an approval is rejected (no double deduction)');
select is((select on_hand from public.stock_balances), 70.000::numeric(14, 3), 'stock moved exactly once');
reset role;

-- Manager in another section cannot touch Section A's store.
select tests.login('e0000000-0000-0000-0000-000000000002');
select is((select count(*)::integer from public.stock_balances), 0, 'other sections cannot see this store''s stock');
reset role;

-- Append-only even for privileged roles.
select throws_like(
  $$update public.stock_ledger set qty_delta = 1$$,
  '%append-only%', 'the ledger cannot be edited, even by the database owner');

select * from finish();
rollback;
