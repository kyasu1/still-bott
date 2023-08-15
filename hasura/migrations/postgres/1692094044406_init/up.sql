SET check_function_bodies = false;
CREATE TABLE public.async_sessions (
    id character varying NOT NULL,
    expires timestamp with time zone,
    session text NOT NULL
);
CREATE TABLE public.media (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id text NOT NULL,
    thumbnail text NOT NULL,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE public.message (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id text NOT NULL,
    text text NOT NULL,
    priority integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    media_id uuid,
    tweeted boolean DEFAULT false NOT NULL,
    tag_id uuid
);
CREATE TABLE public.role (
    value text NOT NULL
);
CREATE TABLE public.session (
    id text NOT NULL,
    access_token text NOT NULL,
    refresh_token text,
    issued_at timestamp with time zone NOT NULL,
    expires_in integer,
    name text,
    user_name text
);
CREATE TABLE public.tag (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id text NOT NULL,
    name text NOT NULL,
    description text
);
CREATE TABLE public.task_fixed_time (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id text NOT NULL,
    tweet_at time without time zone NOT NULL,
    sun boolean DEFAULT true NOT NULL,
    mon boolean DEFAULT true NOT NULL,
    tue boolean DEFAULT true NOT NULL,
    wed boolean DEFAULT true NOT NULL,
    thu boolean DEFAULT true NOT NULL,
    fri boolean DEFAULT true NOT NULL,
    sat boolean DEFAULT true NOT NULL,
    random boolean DEFAULT true NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tag_id uuid
);
CREATE TABLE public.task_rss (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id text NOT NULL,
    tweet_at time without time zone NOT NULL,
    sun boolean NOT NULL,
    mon boolean NOT NULL,
    tue boolean NOT NULL,
    wed boolean NOT NULL,
    thu boolean NOT NULL,
    fri boolean NOT NULL,
    sat boolean NOT NULL,
    last_pub_date timestamp with time zone,
    url text NOT NULL,
    template text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    random boolean NOT NULL,
    enabled boolean NOT NULL
);
CREATE TABLE public."user" (
    id text NOT NULL,
    email text NOT NULL,
    role text DEFAULT 'anonymous'::text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    registered_at timestamp with time zone DEFAULT now() NOT NULL,
    email_confirmed boolean DEFAULT false NOT NULL,
    email_confirmed_at timestamp with time zone,
    email_confirm_code text,
    email_confirm_code_issued_at timestamp with time zone
);
ALTER TABLE ONLY public.async_sessions
    ADD CONSTRAINT async_sessions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.task_fixed_time
    ADD CONSTRAINT task_fixed_time_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.task_rss
    ADD CONSTRAINT task_rss_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_media_id_fkey FOREIGN KEY (media_id) REFERENCES public.media(id) ON UPDATE SET NULL ON DELETE SET NULL;
ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tag(id) ON UPDATE SET DEFAULT ON DELETE SET DEFAULT;
ALTER TABLE ONLY public.message
    ADD CONSTRAINT message_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.tag
    ADD CONSTRAINT tag_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.task_fixed_time
    ADD CONSTRAINT task_fixed_time_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tag(id) ON UPDATE SET DEFAULT ON DELETE SET DEFAULT;
ALTER TABLE ONLY public.task_fixed_time
    ADD CONSTRAINT task_fixed_time_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.task_rss
    ADD CONSTRAINT task_rss_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_role_fkey FOREIGN KEY (role) REFERENCES public.role(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
