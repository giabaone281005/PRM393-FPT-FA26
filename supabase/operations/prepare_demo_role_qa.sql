-- Development only. Caller supplies ignored build/demo-qa.json as the
-- transaction-local mathlingo.feature_qa setting. Creates isolated QA identities.
DO $$
DECLARE q jsonb:=current_setting('mathlingo.feature_qa')::jsonb; prefix text;
  uid uuid; email_address text; pass text;
BEGIN
  IF q->>'SUPABASE_URL'<>'https://seoswmcldwwytdrfrrrb.supabase.co' THEN
    RAISE EXCEPTION 'Wrong QA project'; END IF;
  FOREACH prefix IN ARRAY ARRAY['QA_ADMIN','QA_OTHER'] LOOP
    uid:=(q->>prefix)::uuid; email_address:=q->>(prefix||'_EMAIL'); pass:=q->>(prefix||'_PASSWORD');
    IF email_address NOT LIKE 'demo-%@example.invalid' OR length(pass)<32 THEN
      RAISE EXCEPTION 'Invalid disposable role fixture'; END IF;
    INSERT INTO auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,
      raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,recovery_token,email_change_token_new,email_change)
    VALUES('00000000-0000-0000-0000-000000000000',uid,'authenticated','authenticated',email_address,
      extensions.crypt(pass,extensions.gen_salt('bf')),now(),
      '{"provider":"email","providers":["email"]}','{}',now(),now(),'','','','');
    INSERT INTO auth.identities(provider_id,user_id,identity_data,provider,created_at,updated_at)
    VALUES(uid::text,uid,jsonb_build_object('sub',uid,'email',email_address),'email',now(),now());
    INSERT INTO public.parents(id,email) VALUES(uid,email_address) ON CONFLICT DO NOTHING;
    INSERT INTO public.subscriptions(parent_id) VALUES(uid) ON CONFLICT DO NOTHING;
    IF prefix='QA_ADMIN' THEN
      INSERT INTO public.user_roles(user_id,role) VALUES(uid,'admin') ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END $$;
