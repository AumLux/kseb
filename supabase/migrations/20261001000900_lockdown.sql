-- =============================================================================
-- Final lockdown, kept as the last migration and re-run whenever functions are
-- added: anonymous callers can execute nothing; authenticated users can only
-- execute the RPCs explicitly granted in earlier migrations (re-granted
-- here so this file is the single checklist of the public API surface).
-- =============================================================================

revoke execute on all functions in schema public from public, anon, authenticated;
revoke execute on all functions in schema private from public, anon;
grant execute on all functions in schema private to authenticated, service_role;
grant execute on all functions in schema public to service_role;

-- Public RPC surface (authenticated only):
grant execute on function
  public.me(),
  public.mark_password_changed(),
  public.update_my_contact(text, text),
  public.people_directory(uuid[]),
  public.check_in(uuid, timestamptz, double precision, double precision, real, boolean, uuid),
  public.check_out(uuid, timestamptz, double precision, double precision, real, boolean),
  public.mark_attendance(uuid, date, public.attendance_status, text),
  public.correct_attendance(uuid, public.attendance_status, timestamptz, timestamptz, text),
  public.verify_attendance(uuid[]),
  public.decide_leave(uuid, boolean, text),
  public.cancel_leave(uuid),
  public.attendance_month(date, uuid),
  public.transition_worksheet(uuid, text, text),
  public.set_worksheet_crew(uuid, uuid[]),
  public.sign_permit_checklist(uuid, text, text, text, boolean, boolean, boolean, text[]),
  public.decide_material_request(uuid, boolean, text),
  public.cancel_material_request(uuid),
  public.adjust_stock(uuid, uuid, numeric, text, boolean),
  public.transfer_stock(uuid, uuid, uuid, numeric, text),
  public.record_asset_event(uuid, text, text, uuid, uuid, public.asset_status, public.asset_condition),
  public.decide_bonus(uuid, boolean, text),
  public.my_approvals(),
  public.dashboard_kpis()
to authenticated;
