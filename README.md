# Say hello to MAOKAI
MAOKAI is a postgres database tailored for saving data relating to League of Legends.

## Required Configuration Values
The following environment variables need to be defined:
- POSTGRES_DB: the name of the database in which to store the tables
- POSTGRES_USER: the name of the owner of the database. Can do everything in the DB.
- POSTGRES_PASSWORD: the password of the owner of the database.
- CLIENT_ROLE: the name of the role associated with populating the database. This role can SELECT, UPDATE, and INSERT on the database, but not DELETE
- CLIENT_PASS: the password for the client role.
- REPORTER_ROLE: the name of the role associated with reporting information about the database. This role can only do SELECTs on the database.
- REPORTER_PASS: the password for the reporter role.

## How it works
MAOKAI is based on the default Docker container for postgres 9.6. It extends the configuration with a simple `init-script.sh` file that contains the instructions to setup the database.

MAOKAI also makes use of a `seeds.csv` file to pre-populate the summoner table with a minimum of information.
