-- =============================================================================
-- Sample reference data (local dev and staging). Contains NO user accounts.
--
-- * Org hierarchy: an illustrative Ernakulam set. Replace it with the client's
--   real circles/divisions/sections in-app (Admin › Organisation).
-- * Holidays: only fixed-date Kerala/national holidays. Lunar-calendar
--   holidays (Vishu, Onam, Eid, Deepavali, ...) change every year and must
--   be added from the Kerala Government holiday notification each year.
-- * Material catalogue: common distribution-line consumables.
-- =============================================================================

insert into public.circles (id, code, name) values
  ('11111111-0000-4000-8000-000000000001', 'EC-EKM', 'Electrical Circle, Ernakulam')
on conflict (code) do nothing;

insert into public.divisions (id, circle_id, code, name) values
  ('22222222-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000001', 'ED-EKM', 'Electrical Division, Ernakulam'),
  ('22222222-0000-4000-8000-000000000002', '11111111-0000-4000-8000-000000000001', 'ED-ALV', 'Electrical Division, Aluva')
on conflict (code) do nothing;

insert into public.subdivisions (id, division_id, code, name) values
  ('33333333-0000-4000-8000-000000000001', '22222222-0000-4000-8000-000000000001', 'ESD-KLR', 'Electrical Sub-division, Kaloor'),
  ('33333333-0000-4000-8000-000000000002', '22222222-0000-4000-8000-000000000002', 'ESD-ALV', 'Electrical Sub-division, Aluva')
on conflict (code) do nothing;

insert into public.sections (id, subdivision_id, code, name, address, lat, lng, geofence_radius_m) values
  ('44444444-0000-4000-8000-000000000001', '33333333-0000-4000-8000-000000000001', 'ES-KLR', 'Electrical Section, Kaloor', 'Kaloor, Kochi', 9.9943, 76.2999, 500),
  ('44444444-0000-4000-8000-000000000002', '33333333-0000-4000-8000-000000000001', 'ES-EDP', 'Electrical Section, Edappally', 'Edappally, Kochi', 10.0261, 76.3125, 500),
  ('44444444-0000-4000-8000-000000000003', '33333333-0000-4000-8000-000000000002', 'ES-ALV', 'Electrical Section, Aluva', 'Aluva', 10.1076, 76.3516, 500)
on conflict (code) do nothing;

insert into public.stores (section_id, name) values
  ('44444444-0000-4000-8000-000000000001', 'Kaloor section store'),
  ('44444444-0000-4000-8000-000000000003', 'Aluva section store')
on conflict (section_id, name) do nothing;

-- Fixed-date holidays for the current and next year.
insert into public.holidays (holiday_date, name)
select make_date(y, m, d), n
from generate_series(extract(year from current_date)::integer, extract(year from current_date)::integer + 1) y
cross join (values
  (1, 2, 'Mannam Jayanthi'),
  (1, 26, 'Republic Day'),
  (5, 1, 'May Day'),
  (8, 15, 'Independence Day'),
  (8, 28, 'Ayyankali Jayanthi'),
  (10, 2, 'Gandhi Jayanthi'),
  (12, 25, 'Christmas')
) as h(m, d, n)
on conflict do nothing;

insert into public.material_catalog (code, name, category, unit, reorder_level) values
  ('CND-ACSR-RAB', 'ACSR conductor — Rabbit', 'Conductor', 'm', 500),
  ('CND-ACSR-WSL', 'ACSR conductor — Weasel', 'Conductor', 'm', 500),
  ('CND-ACSR-RCN', 'ACSR conductor — Raccoon', 'Conductor', 'm', 300),
  ('CBL-ABC-3X50', 'LT aerial bunched cable 3×50+1×35 sq mm', 'Cable', 'm', 200),
  ('CBL-XLPE-11KV', '11kV XLPE cable 3×300 sq mm', 'Cable', 'm', 50),
  ('PLE-PSC-8M', 'PSC pole 8 m', 'Pole', 'nos', 10),
  ('PLE-PSC-9M', 'PSC pole 9 m', 'Pole', 'nos', 10),
  ('INS-PIN-11KV', '11kV pin insulator with pin', 'Insulator', 'nos', 50),
  ('INS-DISC-70KN', 'Disc insulator 70 kN', 'Insulator', 'nos', 30),
  ('INS-SHK-LT', 'LT shackle insulator', 'Insulator', 'nos', 100),
  ('HW-XARM-V', 'V cross arm (MS)', 'Hardware', 'nos', 20),
  ('HW-STAY-SET', 'Stay set complete (rod, plate, clamp)', 'Hardware', 'set', 20),
  ('HW-GI-STAY-7/8', 'GI stay wire 7/8 SWG', 'Hardware', 'kg', 100),
  ('HW-EARTH-PIPE', 'GI earth pipe 40 mm × 2.5 m', 'Earthing', 'nos', 20),
  ('PRT-LA-9KV', 'Lightning arrester 9 kV', 'Protection', 'nos', 10),
  ('PRT-DO-FUSE', 'DO fuse unit 11kV', 'Protection', 'set', 10),
  ('SW-AB-11KV', 'AB switch 11kV 400 A', 'Switchgear', 'set', 2),
  ('MTR-1PH-SM', 'Single-phase static energy meter', 'Metering', 'nos', 25)
on conflict (code) do nothing;
