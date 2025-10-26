-- Cassandra setup script for KL-Recycling App
-- Run this script after starting Cassandra to create keyspace and tables

-- Create keyspace
CREATE KEYSPACE IF NOT EXISTS kl_recycling
WITH REPLICATION = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

-- Use the keyspace
USE kl_recycling;

-- Create user table
CREATE TABLE IF NOT EXISTS users (
  id text PRIMARY KEY,
  email text,
  name text,
  password text,
  phone text,
  company text,
  profile_image text,
  push_token text,
  notification_settings map<text, boolean>,
  created_at timestamp
);

-- Create index on email for login lookups
CREATE INDEX IF NOT EXISTS ON users (email);

-- Create quote_requests table
CREATE TABLE IF NOT EXISTS quote_requests (
  id text PRIMARY KEY,
  user_id text,
  name text,
  email text,
  phone text,
  company text,
  material text,
  quantity text,
  notes text,
  photos list<text>,
  status text,
  created_at timestamp
);

-- Create schedules table
CREATE TABLE IF NOT EXISTS schedules (
  id text PRIMARY KEY,
  user_id text,
  name text,
  email text,
  phone text,
  company text,
  material_type text,
  pickup_address text,
  pickup_date date,
  notes text,
  photos list<text>,
  status text,
  confirmation_id text,
  confirmed_by text,
  confirmed_at timestamp,
  created_at timestamp
);

-- Create uploads table for file tracking
CREATE TABLE IF NOT EXISTS uploads (
  id text PRIMARY KEY,
  user_id text,
  filename text,
  original_name text,
  mimetype text,
  size bigint,
  upload_date timestamp,
  purpose text
);
