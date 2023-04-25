CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);

CREATE TABLE tanuki_bot_mvc (
    id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    embedding vector(1536) NOT NULL,
    url text NOT NULL,
    content text NOT NULL,
    metadata jsonb NOT NULL,
    chroma_id text,
    CONSTRAINT check_5df597f0fb CHECK ((char_length(url) <= 2048)),
    CONSTRAINT check_67053ce605 CHECK ((char_length(content) <= 32768)),
    CONSTRAINT check_e130e042d4 CHECK ((char_length(chroma_id) <= 512))
);

CREATE SEQUENCE tanuki_bot_mvc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE tanuki_bot_mvc_id_seq OWNED BY tanuki_bot_mvc.id;

ALTER TABLE ONLY tanuki_bot_mvc ALTER COLUMN id SET DEFAULT nextval('tanuki_bot_mvc_id_seq'::regclass);

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);

ALTER TABLE ONLY tanuki_bot_mvc
    ADD CONSTRAINT tanuki_bot_mvc_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX index_tanuki_bot_mvc_on_chroma_id ON tanuki_bot_mvc USING btree (chroma_id);
