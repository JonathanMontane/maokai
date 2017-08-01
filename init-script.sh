#!/bin/bash
set -e

echo "db - $POSTGRES_DB, name - $POSTGRES_USER"

psql -v ON_ERROR_STOP=1 -d "$POSTGRES_DB" --username "$POSTGRES_USER" <<-EOSQL
  CREATE ROLE $CLIENT_ROLE WITH LOGIN PASSWORD '$CLIENT_PASS';
  CREATE ROLE $REPORTER_ROLE WITH LOGIN PASSWORD '$REPORTER_PASS';

  SET statement_timeout = 0;
  SET client_encoding = 'UTF8';
  SET standard_conforming_strings = on;
  SET check_function_bodies = false;
  SET client_min_messages = warning;

  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  
  CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

  COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

  SET search_path = public, pg_catalog;
  SET default_tablespace = '';
  SET default_with_oids = false;

  CREATE TABLE summoner (
      id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
      account_id bigint UNIQUE,
      name text,
      summoner_id bigint UNIQUE NOT NULL,
      platform_id text NOT NULL,
      is_seed boolean DEFAULT TRUE,
      is_fresh boolean DEFAULT FALSE,
      last_checked_at timestamp without time zone
  );
  CREATE TABLE match (
      match_id bigint PRIMARY KEY,
      platform_id text NOT NULL,
      season_id int,
      queue_id int,
      map_id int,
      duration int,
      is_seed boolean DEFAULT TRUE,
      is_imported boolean DEFAULT FALSE,
      created_at timestamp without time zone NOT NULL
  );
  CREATE TABLE team (
      team_id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
      match_id bigint NOT NULL,
      first_drake boolean DEFAULT FALSE,
      first_herald boolean DEFAULT FALSE,
      first_baron boolean DEFAULT FALSE,
      first_inhibitor boolean DEFAULT FALSE,
      side int NOT NULL
  );
  CREATE TABLE ban (
      ban_id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
      match_id bigint NOT NULL,
      champion_id int NOT NULL,
      side int NOT NULL,
      turn int NOT NULL
  );
  CREATE TABLE frame (
      frame_id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
      match_id bigint NOT NULL,
      minute int,
      frame_timestamp bigint NOT NULL
  );
  CREATE TABLE participant (
      participant_id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
      match_id bigint NOT NULL,
      account_id bigint NOT NULL,
      role text NOT NULL,
      side text NOT NULL,
      champion_id integer
  );
  CREATE TABLE participant_frame (
      participant_frame_id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
      participant_id uuid NOT NULL,
      frame_id uuid NOT NULL,
      total_gold bigint NOT NULL,
      current_gold bigint NOT NULL,
      minions_killed integer NOT NULL,
      jungle_minions_killed integer NOT NULL,
      level integer NOT NULL,
      experience bigint NOT NULL,
      position_x bigint,
      position_y bigint
  );
  CREATE TABLE event (
      event_id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
      frame_id uuid NOT NULL,
      type text NOT NULL,
      timestamp bigint NOT NULL,
      tower_type text,
      team_id integer,
      killer_id uuid,
      level_up_type text,
      participant_id uuid,
      creator_id uuid,
      position_x bigint,
      position_y bigint,
      assisting_participant_ids uuid[],
      ward_type text,
      monster_type text,
      monster_sub_type text,
      skill_slot integer,
      victim_id uuid,
      before_id integer,
      after_id integer,
      item_id integer,
      building_type text,
      lane_type text
  );

  ALTER TABLE ONLY frame ADD CONSTRAINT match_fk FOREIGN KEY (match_id) REFERENCES match (match_id);
  ALTER TABLE ONLY team ADD CONSTRAINT match_fk FOREIGN KEY (match_id) REFERENCES match (match_id);
  ALTER TABLE ONLY ban ADD CONSTRAINT match_fk FOREIGN KEY (match_id) REFERENCES match (match_id);
  ALTER TABLE ONLY participant_frame ADD CONSTRAINT participant_fk FOREIGN KEY (participant_id) REFERENCES participant (participant_id);
  ALTER TABLE ONLY participant_frame ADD CONSTRAINT frame_fk FOREIGN KEY (frame_id) REFERENCES frame (frame_id);
  ALTER TABLE ONLY event ADD CONSTRAINT frame_fk FOREIGN KEY (frame_id) REFERENCES frame (frame_id);

  CREATE INDEX summoner_by_summoner_id ON summoner (summoner_id);
  CREATE INDEX summoner_by_account_id_partial ON summoner (account_id) WHERE account_id IS NOT NULL;
  CREATE INDEX summoner_seed_partial ON summoner (id) WHERE is_seed IS TRUE;
  CREATE INDEX summoner_fresh_partial ON summoner (id) WHERE is_seed IS FALSE AND is_fresh IS TRUE;
  CREATE INDEX summoner_visited_account_partial ON summoner (id) WHERE account_id IS NOT NULL AND last_checked_at IS NOT NULL;

  CREATE INDEX match_seed_partial ON match (match_id) WHERE is_seed IS TRUE;
  CREATE INDEX match_not_imported_partial ON match (match_id) WHERE is_imported IS FALSE;
  CREATE INDEX match_imported_partial ON match (match_id) WHERE is_imported IS TRUE;

  GRANT SELECT, UPDATE, INSERT ON summoner to $CLIENT_ROLE;
  GRANT SELECT, UPDATE, INSERT ON match to $CLIENT_ROLE;
  GRANT SELECT, UPDATE, INSERT ON team to $CLIENT_ROLE;
  GRANT SELECT, UPDATE, INSERT ON ban to $CLIENT_ROLE;
  GRANT SELECT, UPDATE, INSERT ON frame to $CLIENT_ROLE;
  GRANT SELECT, UPDATE, INSERT ON participant to $CLIENT_ROLE;
  GRANT SELECT, UPDATE, INSERT ON participant_frame to $CLIENT_ROLE;
  GRANT SELECT, UPDATE, INSERT ON event to $CLIENT_ROLE;

  GRANT SELECT ON summoner to $REPORTER_ROLE;
  GRANT SELECT ON match to $REPORTER_ROLE;
  GRANT SELECT ON team to $REPORTER_ROLE;
  GRANT SELECT ON ban to $REPORTER_ROLE;
  GRANT SELECT ON frame to $REPORTER_ROLE;
  GRANT SELECT ON participant to $REPORTER_ROLE;
  GRANT SELECT ON participant_frame to $REPORTER_ROLE;
  GRANT SELECT ON event to $REPORTER_ROLE;

  COPY summoner (summoner_id, platform_id) FROM '/seeds.csv' DELIMITER ',' CSV HEADER;
EOSQL
