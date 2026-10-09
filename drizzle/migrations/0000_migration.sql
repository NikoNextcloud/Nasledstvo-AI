CREATE TYPE public.app_role AS ENUM ('admin','user');
CREATE TYPE public.family_role AS ENUM ('owner','editor','viewer');

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  email text,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

CREATE POLICY "own roles" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "own profile read" ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid() OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "own profile write" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid());
CREATE POLICY "own profile insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (id = auth.uid());

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, email)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name', split_part(NEW.email,'@',1)), NEW.email);
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'user');
  IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'admin') THEN
    INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'admin');
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TABLE public.families (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (char_length(name) BETWEEN 1 AND 120),
  description text,
  owner_id uuid NOT NULL,
  face_grouping_consent boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.families TO authenticated;
GRANT ALL ON public.families TO service_role;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.family_members (
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  role public.family_role NOT NULL DEFAULT 'viewer',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (family_id, user_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.family_members TO authenticated;
GRANT ALL ON public.family_members TO service_role;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_member(_family uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.family_members WHERE family_id = _family AND user_id = auth.uid())
$$;
CREATE OR REPLACE FUNCTION public.can_edit(_family uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.family_members WHERE family_id = _family AND user_id = auth.uid() AND role IN ('owner','editor'))
$$;
CREATE OR REPLACE FUNCTION public.is_owner(_family uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.family_members WHERE family_id = _family AND user_id = auth.uid() AND role = 'owner')
$$;

CREATE POLICY "members read family" ON public.families FOR SELECT TO authenticated USING (public.is_member(id) OR owner_id = auth.uid());
CREATE POLICY "create family" ON public.families FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());
CREATE POLICY "owner updates family" ON public.families FOR UPDATE TO authenticated USING (public.is_owner(id));
CREATE POLICY "owner deletes family" ON public.families FOR DELETE TO authenticated USING (public.is_owner(id));

CREATE POLICY "members read members" ON public.family_members FOR SELECT TO authenticated USING (public.is_member(family_id));
CREATE POLICY "owner manages members" ON public.family_members FOR UPDATE TO authenticated USING (public.is_owner(family_id) AND user_id <> auth.uid()) WITH CHECK (role <> 'owner');
CREATE POLICY "owner removes members or self leave" ON public.family_members FOR DELETE TO authenticated USING ((public.is_owner(family_id) AND user_id <> auth.uid()) OR (user_id = auth.uid() AND role <> 'owner'));

CREATE OR REPLACE FUNCTION public.handle_new_family()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.family_members (family_id, user_id, role) VALUES (NEW.id, NEW.owner_id, 'owner');
  RETURN NEW;
END $$;
CREATE TRIGGER on_family_created AFTER INSERT ON public.families FOR EACH ROW EXECUTE FUNCTION public.handle_new_family();

CREATE TABLE public.invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  email text NOT NULL,
  role public.family_role NOT NULL DEFAULT 'viewer' CHECK (role <> 'owner'),
  token text NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(24),'hex'),
  created_by uuid NOT NULL,
  accepted_at timestamptz,
  expires_at timestamptz NOT NULL DEFAULT now() + interval '14 days',
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, DELETE ON public.invitations TO authenticated;
GRANT ALL ON public.invitations TO service_role;
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner reads invites" ON public.invitations FOR SELECT TO authenticated USING (public.is_owner(family_id));
CREATE POLICY "owner creates invites" ON public.invitations FOR INSERT TO authenticated WITH CHECK (public.is_owner(family_id) AND created_by = auth.uid());
CREATE POLICY "owner deletes invites" ON public.invitations FOR DELETE TO authenticated USING (public.is_owner(family_id));

CREATE OR REPLACE FUNCTION public.accept_invitation(_token text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE inv public.invitations;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Необходим е вход'; END IF;
  SELECT * INTO inv FROM public.invitations WHERE token = _token;
  IF inv.id IS NULL THEN RAISE EXCEPTION 'Поканата не е намерена'; END IF;
  IF inv.accepted_at IS NOT NULL THEN RAISE EXCEPTION 'Поканата вече е използвана'; END IF;
  IF inv.expires_at < now() THEN RAISE EXCEPTION 'Поканата е изтекла'; END IF;
  IF lower(inv.email) <> lower((SELECT email FROM auth.users WHERE id = auth.uid())) THEN
    RAISE EXCEPTION 'Поканата е за друг имейл адрес';
  END IF;
  INSERT INTO public.family_members (family_id, user_id, role) VALUES (inv.family_id, auth.uid(), inv.role)
    ON CONFLICT (family_id, user_id) DO NOTHING;
  UPDATE public.invitations SET accepted_at = now() WHERE id = inv.id;
  RETURN inv.family_id;
END $$;

CREATE TABLE public.albums (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  album_id uuid REFERENCES public.albums(id) ON DELETE SET NULL,
  storage_path text NOT NULL,
  title text,
  description text,
  date_text text,
  year int,
  place text,
  tags text[] NOT NULL DEFAULT '{}',
  size_bytes bigint NOT NULL DEFAULT 0,
  mime text,
  uploaded_by uuid NOT NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.photo_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  photo_id uuid NOT NULL REFERENCES public.photos(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('restore','colorize','enhance')),
  storage_path text,
  is_ai boolean NOT NULL DEFAULT true,
  status text NOT NULL DEFAULT 'pending',
  error text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.stories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  title text NOT NULL,
  narrator text,
  audio_path text,
  transcript text,
  ai_chapter text,
  ai_questions text,
  approved boolean NOT NULL DEFAULT false,
  year int,
  created_by uuid NOT NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  title text NOT NULL,
  storage_path text,
  language text,
  ocr_text text,
  ocr_confidence text,
  needs_review boolean NOT NULL DEFAULT true,
  corrected_text text,
  translation text,
  year int,
  size_bytes bigint NOT NULL DEFAULT 0,
  created_by uuid NOT NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.people (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  first_name text NOT NULL,
  last_name text,
  gender text,
  birth_date text,
  birth_approx boolean NOT NULL DEFAULT false,
  death_date text,
  death_approx boolean NOT NULL DEFAULT false,
  is_living boolean NOT NULL DEFAULT true,
  is_minor boolean NOT NULL DEFAULT false,
  birth_place text,
  bio text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.relationships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('parent','partner')),
  person_a uuid NOT NULL REFERENCES public.people(id) ON DELETE CASCADE,
  person_b uuid NOT NULL REFERENCES public.people(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (person_a <> person_b),
  UNIQUE (kind, person_a, person_b)
);

CREATE TABLE public.book_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text,
  position int NOT NULL DEFAULT 0,
  photo_ids uuid[] NOT NULL DEFAULT '{}',
  story_ids uuid[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.ai_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
  kind text NOT NULL,
  target_id uuid,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','done','failed')),
  error text,
  model text,
  cost_cents int NOT NULL DEFAULT 0,
  created_by uuid NOT NULL DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz
);

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['albums','photos','photo_versions','stories','documents','people','relationships','book_sections','ai_jobs'] LOOP
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    EXECUTE format('GRANT ALL ON public.%I TO service_role', t);
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY "members read" ON public.%I FOR SELECT TO authenticated USING (public.is_member(family_id))', t);
    EXECUTE format('CREATE POLICY "editors insert" ON public.%I FOR INSERT TO authenticated WITH CHECK (public.can_edit(family_id))', t);
    EXECUTE format('CREATE POLICY "editors update" ON public.%I FOR UPDATE TO authenticated USING (public.can_edit(family_id))', t);
    EXECUTE format('CREATE POLICY "editors delete" ON public.%I FOR DELETE TO authenticated USING (public.can_edit(family_id))', t);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.validate_relationship()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
DECLARE cyc boolean; pc int;
BEGIN
  IF (SELECT family_id FROM public.people WHERE id = NEW.person_a) <> NEW.family_id
     OR (SELECT family_id FROM public.people WHERE id = NEW.person_b) <> NEW.family_id THEN
    RAISE EXCEPTION 'Хората трябва да са от същия архив';
  END IF;
  IF NEW.kind = 'parent' THEN
    SELECT count(*) INTO pc FROM public.relationships WHERE kind='parent' AND person_b = NEW.person_b AND id <> NEW.id;
    IF pc >= 2 THEN RAISE EXCEPTION 'Човекът вече има двама родители'; END IF;
    WITH RECURSIVE anc AS (
      SELECT person_a AS id FROM public.relationships WHERE kind='parent' AND person_b = NEW.person_a
      UNION
      SELECT r.person_a FROM public.relationships r JOIN anc ON r.person_b = anc.id WHERE r.kind='parent'
    ) SELECT EXISTS (SELECT 1 FROM anc WHERE id = NEW.person_b) INTO cyc;
    IF cyc THEN RAISE EXCEPTION 'Невалидна връзка: би създала цикъл (потомък не може да е родител)'; END IF;
    IF EXISTS (SELECT 1 FROM public.relationships WHERE kind='partner' AND ((person_a=NEW.person_a AND person_b=NEW.person_b) OR (person_a=NEW.person_b AND person_b=NEW.person_a))) THEN
      RAISE EXCEPTION 'Партньорите не могат да са родител и дете';
    END IF;
  ELSE
    IF EXISTS (SELECT 1 FROM public.relationships WHERE kind='partner' AND person_a=NEW.person_b AND person_b=NEW.person_a) THEN
      RAISE EXCEPTION 'Връзката вече съществува';
    END IF;
    IF EXISTS (SELECT 1 FROM public.relationships WHERE kind='parent' AND ((person_a=NEW.person_a AND person_b=NEW.person_b) OR (person_a=NEW.person_b AND person_b=NEW.person_a))) THEN
      RAISE EXCEPTION 'Родител и дете не могат да са партньори';
    END IF;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER validate_relationship BEFORE INSERT OR UPDATE ON public.relationships FOR EACH ROW EXECUTE FUNCTION public.validate_relationship();

CREATE TABLE public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  description text,
  kind text NOT NULL CHECK (kind IN ('subscription','one_time','book')),
  price_cents int NOT NULL CHECK (price_cents >= 0),
  currency text NOT NULL DEFAULT 'EUR' CHECK (currency = 'EUR'),
  discount_percent int NOT NULL DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 100),
  interval text CHECK (interval IN ('month','year')),
  features text[] NOT NULL DEFAULT '{}',
  limits jsonb NOT NULL DEFAULT '{}',
  active boolean NOT NULL DEFAULT true,
  position int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.products TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.products TO service_role;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads active" ON public.products FOR SELECT TO anon, authenticated USING (active OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "admin writes" ON public.products FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.book_options (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind text NOT NULL CHECK (kind IN ('format','cover')),
  code text NOT NULL,
  label text NOT NULL,
  surcharge_cents int NOT NULL DEFAULT 0 CHECK (surcharge_cents >= 0),
  active boolean NOT NULL DEFAULT true,
  position int NOT NULL DEFAULT 0,
  UNIQUE (kind, code)
);
GRANT SELECT ON public.book_options TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.book_options TO authenticated;
GRANT ALL ON public.book_options TO service_role;
ALTER TABLE public.book_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public reads active" ON public.book_options FOR SELECT TO anon, authenticated USING (active OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "admin writes" ON public.book_options FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE TABLE public.price_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity text NOT NULL,
  entity_id uuid,
  action text NOT NULL,
  old_data jsonb,
  new_data jsonb,
  changed_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.price_history TO authenticated;
GRANT ALL ON public.price_history TO service_role;
ALTER TABLE public.price_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin reads history" ON public.price_history FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));

CREATE OR REPLACE FUNCTION public.log_price_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.price_history (entity, entity_id, action, old_data, new_data, changed_by)
  VALUES (TG_TABLE_NAME, COALESCE(NEW.id, OLD.id), TG_OP,
    CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END, auth.uid());
  RETURN COALESCE(NEW, OLD);
END $$;
CREATE TRIGGER products_history AFTER INSERT OR UPDATE OR DELETE ON public.products FOR EACH ROW EXECUTE FUNCTION public.log_price_change();
CREATE TRIGGER book_options_history AFTER INSERT OR UPDATE OR DELETE ON public.book_options FOR EACH ROW EXECUTE FUNCTION public.log_price_change();

CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  family_id uuid REFERENCES public.families(id) ON DELETE SET NULL,
  kind text NOT NULL,
  product_snapshot jsonb NOT NULL,
  amount_cents int NOT NULL,
  currency text NOT NULL DEFAULT 'EUR' CHECK (currency = 'EUR'),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','failed','canceled','refunded')),
  provider_session_id text,
  shipping jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  paid_at timestamptz
);
GRANT SELECT ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own or admin orders" ON public.orders FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'));

CREATE TABLE public.consent_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid(),
  family_id uuid,
  kind text NOT NULL,
  granted boolean NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.consent_log TO authenticated;
GRANT ALL ON public.consent_log TO service_role;
ALTER TABLE public.consent_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own consent read" ON public.consent_log FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.has_role(auth.uid(),'admin'));
CREATE POLICY "own consent insert" ON public.consent_log FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE TABLE public.audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor uuid DEFAULT auth.uid(),
  action text NOT NULL,
  entity text,
  entity_id text,
  details jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT ON public.audit_log TO authenticated;
GRANT ALL ON public.audit_log TO service_role;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin reads audit" ON public.audit_log FOR SELECT TO authenticated USING (public.has_role(auth.uid(),'admin'));
CREATE POLICY "self insert audit" ON public.audit_log FOR INSERT TO authenticated WITH CHECK (actor = auth.uid());

CREATE TABLE public.app_settings (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.app_settings TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.app_settings TO authenticated;
GRANT ALL ON public.app_settings TO service_role;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read settings" ON public.app_settings FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "admin write settings" ON public.app_settings FOR ALL TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

CREATE OR REPLACE FUNCTION public.admin_overview()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(),'admin') THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN jsonb_build_object(
    'users', (SELECT count(*) FROM public.profiles),
    'families', (SELECT count(*) FROM public.families),
    'photos', (SELECT count(*) FROM public.photos),
    'stories', (SELECT count(*) FROM public.stories),
    'documents', (SELECT count(*) FROM public.documents),
    'storage_bytes', (SELECT COALESCE(sum(size_bytes),0) FROM public.photos) + (SELECT COALESCE(sum(size_bytes),0) FROM public.documents),
    'ai_jobs', (SELECT count(*) FROM public.ai_jobs),
    'ai_failed', (SELECT count(*) FROM public.ai_jobs WHERE status='failed'),
    'ai_cost_cents', (SELECT COALESCE(sum(cost_cents),0) FROM public.ai_jobs),
    'orders', (SELECT count(*) FROM public.orders)
  );
END $$;

CREATE OR REPLACE FUNCTION public.admin_families()
RETURNS TABLE (id uuid, name text, owner_email text, members bigint, photos bigint, storage_bytes bigint, created_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(),'admin') THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT f.id, f.name, p.email,
    (SELECT count(*) FROM public.family_members m WHERE m.family_id=f.id),
    (SELECT count(*) FROM public.photos ph WHERE ph.family_id=f.id),
    ((SELECT COALESCE(sum(ph.size_bytes),0) FROM public.photos ph WHERE ph.family_id=f.id) + (SELECT COALESCE(sum(d.size_bytes),0) FROM public.documents d WHERE d.family_id=f.id))::bigint,
    f.created_at
  FROM public.families f LEFT JOIN public.profiles p ON p.id=f.owner_id ORDER BY f.created_at DESC;
END $$;

CREATE OR REPLACE FUNCTION public.admin_ai_jobs()
RETURNS TABLE (id uuid, kind text, status text, model text, cost_cents int, error text, created_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_role(auth.uid(),'admin') THEN RAISE EXCEPTION 'Forbidden'; END IF;
  RETURN QUERY SELECT j.id, j.kind, j.status, j.model, j.cost_cents, j.error, j.created_at FROM public.ai_jobs j ORDER BY j.created_at DESC LIMIT 200;
END $$;

CREATE POLICY "family media read" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id='family-media' AND public.is_member(((storage.foldername(name))[1])::uuid));
CREATE POLICY "family media insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id='family-media' AND public.can_edit(((storage.foldername(name))[1])::uuid));
CREATE POLICY "family media delete" ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id='family-media' AND public.can_edit(((storage.foldername(name))[1])::uuid));

INSERT INTO public.products (slug, name, description, kind, price_cents, interval, features, limits, position) VALUES
('monthly','Семеен абонамент','Жив архив за цялото семейство с AI помощ всеки месец.','subscription',790,'month',
  ARRAY['Неограничени членове на семейството','AI реставрация и OCR','Семейно дърво и разкази','Редактор на семейна книга'],
  '{"photos":5000,"storage_gb":50,"ai_credits":200,"books":1}',1),
('archive-pack','Семеен архив пакет','Еднократна покупка за дигитализиране на семейния архив.','one_time',2490,NULL,
  ARRAY['Безсрочен достъп до архива','100 AI кредита','Експорт на всички данни'],
  '{"photos":1000,"storage_gb":10,"ai_credits":100,"books":0}',2),
('book','Физическа семейна книга','Отпечатана книга с вашите снимки и разкази.','book',7690,NULL,
  ARRAY['Професионален печат','Включени 40 страници','Доставка в ЕС'],
  '{"included_pages":40,"per_extra_page_cents":60,"max_pages":200}',3);

INSERT INTO public.book_options (kind, code, label, surcharge_cents, position) VALUES
('format','a5','A5 (15×21 см)',0,1),
('format','square','Квадрат (21×21 см)',800,2),
('format','a4','A4 (21×30 см)',1800,3),
('cover','soft','Мека корица',0,1),
('cover','hard','Твърда корица',1200,2),
('cover','linen','Ленена корица с релеф',2400,3);

INSERT INTO public.app_settings (key, value) VALUES
('upload_limits', '{"photo_mb":25,"audio_mb":50,"document_mb":25}');