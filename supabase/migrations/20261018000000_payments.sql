create table public.payments (
                                 id uuid primary key default gen_random_uuid(),
                                 parent_id uuid not null references public.parents(id) on delete cascade,
                                 provider text not null check (provider in ('momo','zalopay')),
                                 order_id text not null unique,          -- momo: orderId | zalopay: app_trans_id
                                 amount int not null,
                                 status text not null default 'pending', -- pending | paid | failed
                                 qr_content text,
                                 created_at timestamptz default now()
);
alter table public.payments enable row level security;
create policy "own payments" on public.payments for select to authenticated
                                                        using (parent_id = (select auth.uid()));
alter publication supabase_realtime add table public.payments;

-- Chỉ service_role gọi được (callback)
create or replace function public.activate_plus(p_parent uuid, p_days int)
returns void language plpgsql security definer as $$
declare cur public.subscription_tier;
begin
select tier into cur from public.subscriptions where parent_id = p_parent;
insert into public.subscriptions(parent_id,tier,status,max_kids,start_date,expires_at,notes)
values (p_parent,'plus','active',3,now(),now()+(p_days||' days')::interval,'Thanh toán QR')
    on conflict (parent_id) do update set tier='plus',status='active',max_kids=3,
                                   expires_at = greatest(coalesce(public.subscriptions.expires_at, now()), now()) + (p_days||' days')::interval,
                                   updated_at=now();
insert into public.subscription_logs(parent_id,action,old_tier,new_tier,reason)
values (p_parent,'UPGRADE',cur,'plus','QR payment');
end $$;
revoke all on function public.activate_plus from public, anon, authenticated;