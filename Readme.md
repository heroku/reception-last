# Reception

A simple guest tracking app for vibe.

## Setup

```bash
bundle install
cp .env.example .env
```

**Create an OAuth client**
```bash
heroku plugins:install git://github.com/heroku/heroku-oauth.git
heroku clients:register "reception-localhost" http://localhost:5000/auth/heroku/callback
```

Add these values to `HEROKU_OAUTH_ID` and `HEROKU_OAUTH_SECRET`.

**Create database**
```bash
createdb guest
psql guest -f schema.sql
```

**Enjoy**
```bash
foreman start
```
